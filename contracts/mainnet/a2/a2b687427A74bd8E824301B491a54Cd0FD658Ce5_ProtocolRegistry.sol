// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ProtocolBase.sol";

contract ProtocolRegistry is ProtocolBase {
    uint256 public govPlatformFee;
    uint256 public govAutosellFee;
    uint256 public govThresholdFee;

    // stable coin address enable or disable in protocol registry
    mapping(address => bool) public approveStable;

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();

        require(
            IAdminRegistry(adminRegistry).isAddTokenRole(admin),
            "GovProtocolRegistry: msg.sender not add token admin."
        );
        _;
    }
    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();

        require(
            IAdminRegistry(adminRegistry).isEditTokenRole(admin),
            "GovProtocolRegistry: msg.sender not edit token admin."
        );
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();
        require(
            IAdminRegistry(adminRegistry).isAddSpAccess(admin),
            "GovProtocolRegistry: No admin right to add Strategic Partner"
        );
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        address adminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();

        require(
            IAdminRegistry(adminRegistry).isEditSpAccess(admin),
            "GovProtocolRegistry: No admin right to update or remove Strategic Partner"
        );
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
        govPlatformFee = 150; //1.5 %
        govAutosellFee = 200; //2 % in Calculate APY FEE Function
        govThresholdFee = 200; //2 %
    }

    /// @dev function to set the address provider contract
    /// @param _addressProvider contract address provider
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev function to enable or disale stable coin in the gov protocol
    /// @param _stableAddress stable token contract address DAI, USDT, etc...
    /// @param _status bool value true or false to change status of stable coin
    function addEditStableCoin(
        address[] memory _stableAddress,
        bool[] memory _status
    ) external onlyEditTokenRole(msg.sender) {
        require(
            _stableAddress.length == _status.length,
            "GPR: length mismatch"
        );
        for (uint256 i = 0; i < _stableAddress.length; i++) {
            require(_stableAddress[i] != address(0x0), "GPR: null address");
            require(
                approveStable[_stableAddress[i]] != _status[i],
                "GPR: already in desired state"
            );
            approveStable[_stableAddress[i]] = _status[i];

            emit UpdatedStableCoinStatus(_stableAddress[i], _status[i]);
        }
    }

    /** external functions of the Gov Protocol Contract */

    /// @dev function to add token to approvedTokens mapping
    /// @param _tokenAddress of the new token Address
    /// @param marketData struct of the _tokenAddress

    function addTokens(
        address[] memory _tokenAddress,
        Market[] memory marketData
    ) external onlyAddTokenRole(msg.sender) {
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
            _addToken(_tokenAddress[i], marketData[i]);
        }
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _marketData struct to update the token market

    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external onlyEditTokenRole(msg.sender) {
        require(
            _tokenAddress.length == _marketData.length,
            "GPR: Token Address Length must match Market Data"
        );

        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenApproved(_tokenAddress[i]),
                "GPR: cannot update the token data, add new token address first"
            );

            _updateToken(_tokenAddress[i], _marketData[i]);
            emit TokensUpdated(_tokenAddress[i], _marketData[i]);
        }
    }

    /// @dev function which change the approved token to enable or disable
    /// @param _tokenAddress address which is updating

    function changeTokensStatus(
        address[] memory _tokenAddress,
        bool[] memory _tokenStatus
    ) external onlyEditTokenRole(msg.sender) {
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            require(
                this.isTokenEnabledForCreateLoan(_tokenAddress[i]) !=
                    _tokenStatus[i],
                "GPR: already in desired status"
            );

            approvedTokens[_tokenAddress[i]]
                .isTokenEnabledAsCollateral = _tokenStatus[i];

            emit TokenStatusUpdated(_tokenAddress[i], _tokenStatus[i]);
        }
    }

    /// @dev add sp wallet to the mapping approvedSps
    /// @param _tokenAddress token contract address
    /// @param _walletAddress sp wallet address to add

    function addSp(address _tokenAddress, address _walletAddress)
        external
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            !_isAlreadyAddedSp(_walletAddress),
            "GPR: SP Already Approved"
        );
        _addSp(_tokenAddress, _walletAddress);
    }

    /// @dev remove sp wallet from mapping
    /// @param _tokenAddress token address as a key to remove sp
    /// @param _removeWalletAddress sp wallet address to be removed

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external
        onlyEditSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        require(
            _isAlreadyAddedSp(_removeWalletAddress),
            "GPR: cannot remove the SP, does not exist"
        );

        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (approvedSps[_tokenAddress][i] == _removeWalletAddress) {
                _removeSpKey(_getIndexofAddressfromArray(_removeWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(approvedSps[_tokenAddress][i]),
                    _tokenAddress
                );
            }
        }

        emit SPWalletRemoved(_tokenAddress, _removeWalletAddress);
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );

        _addBulkSps(_tokenAddress, _walletAddress);
    }

    /// @dev function to update the sp wallet
    /// @param _tokenAddress to check if it exit in the array and mapping
    /// @param _oldWalletAddress old wallet address to be updated
    /// @param _newWalletAddress new wallet address

    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        require(_newWalletAddress != _oldWalletAddress, "GPR: same wallet for update not allowed");
        require(
            _isAlreadyAddedSp(_oldWalletAddress),
            "GPR: cannot update the wallet address, wallet address not exist or not a SP"
        );

        _updateSp(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /// @dev external function update bulk SP wallets to the approvedSps
    /// @param _tokenAddress token contract address being updated
    /// @param _oldWalletAddress  array of old sp wallets
    /// @param _newWalletAddress  array of the new sp wallets

    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );
        _updateBulkSps(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP,
            "GPR: not sp"
        );

        for (uint256 i = 0; i < _removeWalletAddress.length; i++) {
            address removeWallet = _removeWalletAddress[i];
            require(
                _isAlreadyAddedSp(removeWallet),
                "GPR: cannot remove the SP, does not exist, not in array"
            );

            // delete approvedSps[_tokenAddress][i];
            //remove SP key from the mapping
            _removeSpKey(_getIndexofAddressfromArray(removeWallet));

            //also remove SP key from specific token address
            _removeSpKeyfromMapping(
                _getIndexofAddressfromArray(_tokenAddress),
                _tokenAddress
            );
        }
    }

    /** Public functions of the Gov Protocol Contract */

    /// @dev get all approved tokens from the allapprovedTokenContracts
    /// @return address[] returns all the approved token contracts
    function getallApprovedTokens() external view returns (address[] memory) {
        return allapprovedTokenContracts;
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
    /// @return Market market data for the approved token address
    function getSingleApproveToken(address _tokenAddress)
        external
        view
        override
        returns (Market memory)
    {
        return approvedTokens[_tokenAddress];
    }

    /// @dev get data of single approved token address return Market Struct
    /// @param _tokenAddress approved token address
    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        override
        returns (
            address,
            bool,
            uint256
        )
    {
        return (
            approvedTokens[_tokenAddress].gToken,
            approvedTokens[_tokenAddress].isMint,
            uint256(approvedTokens[_tokenAddress].tokenType)
        );
    }

    /// @dev function to check if sythetic mint option is on for the approved collateral token
    /// @param _tokenAddress collateral token address
    /// @return bool returns the bool value true or false
    function isSyntheticMintOn(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return
            approvedTokens[_tokenAddress].tokenType == TokenType.ISVIP &&
            approvedTokens[_tokenAddress].isMint;
    }

    /// @dev get all approved Sp wallets
    /// @return address[] returns the approved stragetic partner addresses
    function getAllApprovedSPs() external view returns (address[] memory) {
        return allApprovedSps;
    }

    /// @dev get wallet addresses of single tokenAddress
    /// @param _tokenAddress sp token address
    /// @return address[] returns the wallet addresses of the sp token
    function getSingleTokenSps(address _tokenAddress)
        external
        view
        override
        returns (address[] memory)
    {
        return approvedSps[_tokenAddress];
    }

    /// @dev set the percentage of the Gov Platform Fee to the Gov Lend Market Contracts
    /// @param _percentage percentage which goes to the gov platform

    function setGovPlatfromFee(uint256 _percentage)
        public
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        govPlatformFee = _percentage;
        emit GovPlatformFeeUpdated(_percentage);
    }

    /// @dev set the liquiation thershold percentage
    function setThresholdFee(uint256 _percentage)
        public
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _percentage <= 5000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        govThresholdFee = _percentage;
        emit ThresholdFeeUpdated(_percentage);
    }

    /// @dev set the autosell apy fee percentage
    /// @param _percentage percentage value of the autosell fee
    function setAutosellFee(uint256 _percentage)
        public
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _percentage <= 2000 && _percentage > 0,
            "GPR: Gov Percentage Error"
        );
        govAutosellFee = _percentage;
        emit AutoSellFeeUpdated(_percentage);
    }

    /// @dev get the gov platofrm fee percentage
    function getGovPlatformFee() external view override returns (uint256) {
        return govPlatformFee;
    }

    function getTokenMarket()
        external
        view
        override
        returns (address[] memory)
    {
        return allapprovedTokenContracts;
    }

    function getThresholdPercentage() external view override returns (uint256) {
        return govThresholdFee;
    }

    function getAutosellPercentage() external view override returns (uint256) {
        return govAutosellFee;
    }


    function isStableApproved(address _stable)
        external
        view
        override
        returns (bool)
    {
        return approveStable[_stable];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./interfaces/IProtocolRegistry.sol";
import "./IGTokenFactory.sol";
import "contracts/admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../addressprovider/AddressProvider.sol";

/// @author IdeoFuzion Team
/// @title  Protocol Registry Base Contract
/// @dev abstract contract for the protocol registry contract

abstract contract ProtocolBase is
    OwnableUpgradeable,
    IProtocolRegistry,
    SuperAdminControl
{
    /// tokenAddress => spWalletAddress
    mapping(address => address[]) public approvedSps;
    /// array of all approved SP Wallet Addresses
    address[] public allApprovedSps;
    address public liquidatorContract;
    address public tokenMarket;
    address public gTokenFactory;

    address public addressProvider;

    /// @dev tokenContractAddress => Market struct
    mapping(address => Market) public approvedTokens;

    /// @dev array of all Approved ERC20 Token Contracts
    address[] allapprovedTokenContracts;
    event TokensAdded(
        address indexed tokenAddress,
        address indexed dexRouter,
        address indexed gToken,
        bool isMint,
        TokenType tokenType,
        bool isTokenEnabledAsCollateral
    );
    event TokensUpdated(
        address indexed tokenAddress,
        Market indexed _marketData
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

    /// @dev function to set the liquidator contract used in the deployGToken function
    /// @param _liquidator address of the Gov Liquidator Contract
    function setLiquidatorContractAddress(address _liquidator)
        external
        onlyOwner
    {
        require(_liquidator != address(0), "Liquidator Empty");
        liquidatorContract = _liquidator;
    }

    /// @dev function
    function setTokenMarketAddress(address _tokenMarket) external onlyOwner {
        require(_tokenMarket != address(0), "Market Empty");
        tokenMarket = _tokenMarket;
    }

    function setGTokenFactory(address _tokenFactory) external onlyOwner {
        require(_tokenFactory != address(0), "Factory Empty");
        gTokenFactory = _tokenFactory;
    }

    /** Internal functions of the Gov Protocol Contract */

    /// @dev function to add token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param marketData struct object to be added in approvedTokens mapping

    function _addToken(address _tokenAddress, Market memory marketData)
        internal
    {

        require(_tokenAddress != marketData.dexRouter, "GPL: token and dex address same");

        //adding marketData to the approvedToken mapping
        if (marketData.tokenType == TokenType.ISVIP) {
            require(
                _tokenAddress == marketData.gToken,
                "GPL: gtoken must equal token address"
            );
            require(
                liquidatorContract != address(0x0) &&
                    tokenMarket != address(0x0),
                "GPL: set addresses first"
            );
            address adminRegistry = IAddressProvider(addressProvider)
                .getAdminRegistry();
            marketData.gToken = IGTokenFactory(gTokenFactory).deployGToken(
                _tokenAddress,
                liquidatorContract,
                tokenMarket,
                adminRegistry
            );
        } else {
            marketData.gToken = address(0x0);
            marketData.isMint = false;
        }

        approvedTokens[_tokenAddress] = marketData;

        emit TokensAdded(
            _tokenAddress,
            approvedTokens[_tokenAddress].dexRouter,
            approvedTokens[_tokenAddress].gToken,
            approvedTokens[_tokenAddress].isMint,
            approvedTokens[_tokenAddress].tokenType,
            approvedTokens[_tokenAddress].isTokenEnabledAsCollateral
        );
        allapprovedTokenContracts.push(_tokenAddress);
    }

    /// @dev function to update the token market data
    /// @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    /// @param _marketData struct object to be added in approvedTokens mapping

    function _updateToken(address _tokenAddress, Market memory _marketData)
        internal
    {   
        
        require(_tokenAddress != _marketData.dexRouter, "GPL: token and dex address same");

        //update Token Data  to the approvedTokens mapping
        Market memory _prevTokenData = approvedTokens[_tokenAddress];

        if (
            _prevTokenData.gToken == address(0x0) &&
            _marketData.tokenType == TokenType.ISVIP
        ) {
            address adminRegistry = IAddressProvider(addressProvider)
                .getAdminRegistry();

            address gToken = IGTokenFactory(gTokenFactory).deployGToken(
                _tokenAddress,
                liquidatorContract,
                tokenMarket,
                adminRegistry
            );
            _marketData.gToken = gToken;
        } else if (_prevTokenData.tokenType == TokenType.ISVIP) {
            _marketData.gToken = _prevTokenData.gToken;
        } else {
            _marketData.gToken = address(0x0);
            _marketData.isMint = false;
        }

        approvedTokens[_tokenAddress] = _marketData;
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false if token enable or disbale for collateral
    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return approvedTokens[_tokenAddress].isTokenEnabledAsCollateral;
    }

    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool true or false value for token address
    function isTokenApproved(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        uint256 length = allapprovedTokenContracts.length;
        for (uint256 i = 0; i < length; i++) {
            if (allapprovedTokenContracts[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev internal function to add Strategic Partner Wallet Address to the approvedSps mapping
    /// @param _tokenAddress contract address of the approvedToken Sp
    /// @param _walletAddress sp wallet address added to the approvedSps

    function _addSp(address _tokenAddress, address _walletAddress) internal {
        // add the sp wallet address to the approvedSps mapping
        approvedSps[_tokenAddress].push(_walletAddress);
        // push sp _walletAddress to allApprovedSps array
        allApprovedSps.push(_walletAddress);
        emit SPWalletAdded(_tokenAddress, _walletAddress);
    }

    /// @dev check if _walletAddress is already added Sp in array
    /// @param _walletAddress wallet address checking

    function _isAlreadyAddedSp(address _walletAddress)
        internal
        view
        returns (bool)
    {
        uint256 length = allApprovedSps.length;
        for (uint256 i = 0; i < length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
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
        override
        returns (bool)
    {
        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address currentWallet = approvedSps[_tokenAddress][i];
            if (currentWallet == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /// @dev remove the Sp token address from the allapprovedsps array
    /// @param index index of the sp address being removed from the allApprovedSps

    function _removeSpKey(uint256 index) internal {
        uint256 length = allApprovedSps.length;
        for (uint256 i = index; i < length - 1; i++) {
            allApprovedSps[i] = allApprovedSps[i + 1];
        }
        allApprovedSps.pop();
    }

    /// @dev remove Sp wallet address from the approvedSps mapping across specific tokenaddress
    /// @param index of the approved wallet sp
    /// @param _tokenAddress token contract address of the approvedToken sp

    function _removeSpKeyfromMapping(uint256 index, address _tokenAddress)
        internal
    {
        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = index; i < length - 1; i++) {
            approvedSps[_tokenAddress][i] = approvedSps[_tokenAddress][i + 1];
        }
        approvedSps[_tokenAddress].pop();
    }

    /// @dev getting index of sp from the allApprovedSps array
    /// @param _walletAddress getting this wallet address index
    function _getIndexofAddressfromArray(address _walletAddress)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = allApprovedSps.length;
        for (uint256 i = 0; i < length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
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
        uint256 length = approvedSps[tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (approvedSps[tokenAddress][i] == _walletAddress) {
                return i;
            }
        }
    }

    /// @dev adding bulk sp wallet address to the approvedSps
    /// @param _tokenAddress token contract address as a key for sp wallets
    /// @param _walletAddress sp wallet addresses adding to the approvedSps mapping

    function _addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        internal
    {
        uint256 length = _walletAddress.length;
        for (uint256 i = 0; i < length; i++) {
            //checking Wallet if already added
            require(
                !_isAlreadyAddedSp(_walletAddress[i]),
                "one or more wallet addresses already added in allapprovedSps array"
            );

            approvedSps[_tokenAddress].push(_walletAddress[i]);
            allApprovedSps.push(_walletAddress[i]);
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
        //update wallet addres to the approved Sps mapping

        uint256 length = approvedSps[_tokenAddress].length;
        for (uint256 i = 0; i < length; i++) {
            address oldWalletAddress = approvedSps[_tokenAddress][i];
                _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(oldWalletAddress),
                    _tokenAddress
                );
                approvedSps[_tokenAddress].push(_newWalletAddress);
                allApprovedSps.push(_newWalletAddress);
            
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
            approvedSps[_tokenAddress].push(newWallet);
            allApprovedSps.push(newWallet);
            emit BulkSpWAlletUpdated(_tokenAddress, currentWallet, newWallet);
        }
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
pragma solidity ^0.8.3;

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

interface IProtocolRegistry {
    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool returns the true or false value
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev check fundtion token enable for staking as collateral
    /// @param _tokenAddress address of the collateral token address
    /// @return bool returns true or false value

    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSyntheticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IGTokenFactory {
    function deployGToken(
        address spToken,
        address liquidator,
        address tokenMarket,
        address govAdminRegistry
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../admin/interfaces/IAdminRegistry.sol";

abstract contract SuperAdminControl {
    /// @dev modifier: onlySuper admin is allowed
    modifier onlySuperAdmin(address govAdminRegistry, address admin) {
        require(
            IAdminRegistry(govAdminRegistry).isSuperAdminAccess(admin),
            "not super admin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.3;

import "../market/pausable/PausableImplementation.sol";
import "./IAddressProvider.sol";

contract AddressProvider is PausableImplementation, IAddressProvider {
    
    address public adminRegistry;
    address public protocolRegistry;
    address public priceConsumer;
    address public claimTokenContract;
    address public gTokenFactory;
    address public liquidator;
    address public tokenMarketRegistry;
    address public tokenMarket;
    address public nftMarket;
    address public networkMarket;
    address public govToken;
    address public govTier;
    address public govGovToken;
    address public govNFTTier;
    address public govVCTier;
    address public userTier;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev function to set the admin registry contract
    /// @param _adminRegistry admin registry contract

    function setAdminRegistry(address _adminRegistry) external onlyOwner {
        require(_adminRegistry != address(0), "zero address");
        adminRegistry = _adminRegistry;
    }

    /// @dev function to set the prootocol registry contract
    /// @param _protocolRegistry protocol registry contract

    function setProtocolRegistry(address _protocolRegistry) external onlyOwner {
        require(_protocolRegistry != address(0), "zero address");
        protocolRegistry = _protocolRegistry;
    }

    /// @dev function to set the tier level contract
    /// @param _tierLevel tier level contract

    function setUserTier(address _tierLevel) external onlyOwner {
        require(_tierLevel != address(0), "zero address");
        userTier = _tierLevel;
    }

    /// @dev function to set the price consumer contract
    /// @param _priceConsumer price consumer contract

    function setPriceConsumer(address _priceConsumer) external onlyOwner {
        require(_priceConsumer != address(0), "zero address");
        priceConsumer = _priceConsumer;
    }

    /// @dev function to set the claim token contract
    /// @param _claimToken claim token contract
    function setClaimToken(address _claimToken) external onlyOwner {
        require(_claimToken != address(0), "zero address");
        claimTokenContract = _claimToken;
    }

    /// @dev function to set gov synthetic token factory contract
    /// @param _gTokenFactory contract address of gToken factory
    function setGTokenFacotry(address _gTokenFactory) external onlyOwner {
        require(_gTokenFactory != address(0), "zero address");
        gTokenFactory = _gTokenFactory;
    }

    /// @dev function to set liquidator contract
    /// @param _liquidator contract address of liquidator
    function setLiquidator(address _liquidator) external onlyOwner {
        require(_liquidator != address(0), "zero address");
        liquidator = _liquidator;
    }

    /// @dev function to set token market registry contract
    /// @param _marketRegistry contract address of liquidator
    function setTokenMarketRegistry(address _marketRegistry)
        external
        onlyOwner
    {
        require(_marketRegistry != address(0), "zero address");
        tokenMarketRegistry = _marketRegistry;
    }

    /// @dev function to set token market contract
    /// @param _tokenMarket contract address of token market
    function setTokenMarket(address _tokenMarket) external onlyOwner {
        require(_tokenMarket != address(0), "zero address");
        tokenMarket = _tokenMarket;
    }

    /// @dev function to set nft market contract
    /// @param _nftMarket contract address of token market
    function setNftMarket(address _nftMarket) external onlyOwner {
        require(_nftMarket != address(0), "zero address");
        nftMarket = _nftMarket;
    }

    /// @dev function to set network market contract
    /// @param _networkMarket contract address of the network loan market
    function setNetworkMarket(address _networkMarket) external onlyOwner {
        require(_networkMarket != address(0), "zero address");
        networkMarket = _networkMarket;
    }

    /// @dev function to set gov token address
    /// @param _govToken contract address of the gov token
    function setGovToken(address _govToken) external onlyOwner {
        require(_govToken != address(0), "zero address");
        govToken = _govToken;
    }

    /// @dev function to set gov tier address
    /// @param _govTier contract address of the gov tier
    function setGovtier(address _govTier) external onlyOwner {
        require(_govTier != address(0), "zero address");
        govTier = _govTier;
    }

    /// @dev function to set govGovToken address
    /// @param _govGovToken gov synthetic token address
    function setgovGovToken(address _govGovToken) external onlyOwner {
        require(_govGovToken != address(0), "zero address");
        govGovToken = _govGovToken;
    }

    /// @dev function to set the gov nft tier address
    /// @param _govNftTier gov nft tier contract address
    function setGovNFTTier(address _govNftTier) external onlyOwner {
        require(_govNftTier != address(0), "zero address");
        govNFTTier = _govNftTier;
    }

    /// @dev function to set the gov vc nft tier address
    /// @param _govVCTier gov vc nft tier contract address
    function setVCNFTTier(address _govVCTier) external onlyOwner {
        require(_govVCTier != address(0), "zero address");
        govVCTier = _govVCTier;
    }

    /**
    @dev getter functions to get all the GOV Protocol Contracts
    */

    /// @dev get the gov admin registry contract address
    /// @return address returns the contract address
    function getAdminRegistry() external view override returns (address) {
        return adminRegistry;
    }

    /// @dev get the gov protocol contract address
    /// @return address returns the contract address
    function getProtocolRegistry() external view override returns (address) {
        return protocolRegistry;
    }

    /// @dev get the gov tier level contract address
    /// @return address returns the contract address
    function getUserTier() external view override returns (address) {
        return userTier;
    }

    /// @dev get the gov price consumer contract address
    /// @return address return the contract address
    function getPriceConsumer() external view override returns (address) {
        return priceConsumer;
    }

    /// @dev get the claim token contract address
    /// @return address return the contract address
    function getClaimTokenContract() external view override returns (address) {
        return claimTokenContract;
    }

    /// @dev get the gtokenfactory contract address
    /// @return address return the contract address
    function getGTokenFactory() external view override returns (address) {
        return gTokenFactory;
    }

    /// @dev get the gov liquidator contract address
    /// @return address returns the contract address
    function getLiquidator() external view override returns (address) {
        return liquidator;
    }

    /// @dev get the token market registry contract address
    /// @return address returns the contract address
    function getTokenMarketRegistry() external view override returns (address) {
        return tokenMarketRegistry;
    }

    /// @dev get the token market contract address
    /// @return address returns the contract address
    function getTokenMarket() external view override returns (address) {
        return tokenMarket;
    }

    /// @dev get the nft market contract address
    /// @return address returns the contract address
    function getNftMarket() external view override returns (address) {
        return nftMarket;
    }

    /// @dev get the network market contract address
    /// @return address returns the contract address

    function getNetworkMarket() external view override returns (address) {
        return networkMarket;
    }

    /// @dev get the gov token contract address
    /// @return address returns the contract address

    function govTokenAddress() external view override returns (address) {
        return govToken;
    }

    /// @dev get the gov tier contract address
    /// @return address returns the contract address
    function getGovTier() external view override returns (address) {
        return govTier;
    }

    /// @dev get the gov synthetic token
    /// @return address returns the contract address
    function getgovGovToken() external view override returns (address) {
        return govGovToken;
    }

    /// @dev get the gov nft tier address;
    /// @return address returns the contract address
    function getGovNFTTier() external view override returns (address) {
        return govNFTTier;
    }

    /// @dev get the gov nc nft tier address
    function getVCTier() external view override returns (address) {
        return govVCTier;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @dev contract used in the token market, NFT market, and network loan market
abstract contract PausableImplementation is
    PausableUpgradeable,
    OwnableUpgradeable
{
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @dev interface use in all the gov platform contracts
interface IAddressProvider {
    function getAdminRegistry() external view returns (address);

    function getProtocolRegistry() external view returns (address);

    function getPriceConsumer() external view returns (address);

    function getClaimTokenContract() external view returns (address);

    function getGTokenFactory() external view returns (address);

    function getLiquidator() external view returns (address);

    function getTokenMarketRegistry() external view returns (address);

    function getTokenMarket() external view returns (address);

    function getNftMarket() external view returns (address);

    function getNetworkMarket() external view returns (address);

    function govTokenAddress() external view returns (address);

    function getGovTier() external view returns (address);

    function getgovGovToken() external view returns (address);

    function getGovNFTTier() external view returns (address);

    function getVCTier() external view returns (address);

    function getUserTier() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}