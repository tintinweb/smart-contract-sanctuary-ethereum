pragma solidity 0.8.4;

import "./interfaces/IWhitelist.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is IWhitelist, Ownable {
    mapping(address => DataProvider) public dataProviders;
    mapping(address => DataFeed[]) public dataFeeds;
    mapping(address => bool) public collateralTokens;

    constructor(address _contractOwner) {
        require(_contractOwner != address(0), "Whitelist: owner is 0x0");
        transferOwnership(_contractOwner);
    }
        
    function addDataProviders(address[] calldata _dataProvider, DataProvider[] calldata _dataProviderInfo)
        external
        override
        onlyOwner
    {
        uint256 length = _dataProvider.length;
        require(length == _dataProviderInfo.length, "Whitelist: different length");
        for (uint256 i = 0; i < length; ) {
            require(_dataProvider[i] != address(0), "Whitelist: null address");
            // Name should not be empty; key for _dataProviderExists check
            require(bytes(_dataProviderInfo[i].name).length != 0, "Whitelist: no name");
            // Prevent double entries in subgraph
            require(
                _dataProviderExists(_dataProvider[i]) != true,
                "Whitelist: entry already exists"
            );

            dataProviders[_dataProvider[i]] = _dataProviderInfo[i];
            emit DataProviderAdded(_dataProvider[i]);
            
            unchecked {
                i++;
            }
        }
    }

    function deleteDataProviders(address[] calldata _dataProvider)
        external
        override
        onlyOwner
    {
        uint256 length = _dataProvider.length;
        for (uint256 i = 0; i < length; ) {
            delete dataProviders[_dataProvider[i]];
            emit DataProviderDeleted(_dataProvider[i]);

            unchecked {
                i++;
            }
        }
    }

    function updateDataProviderNames(
        address[] calldata _dataProvider,
        string[] calldata _newName
    ) external override onlyOwner {
        uint256 length = _dataProvider.length;
        require(
            length == _newName.length,
            "Whitelist: different length"
        );

        for (uint256 i = 0; i < length; ) {
            require(
                _dataProviderExists(_dataProvider[i]) == true,
                "Whitelist: does not exist"
            );

            DataProvider storage dataProvider = dataProviders[_dataProvider[i]];
            dataProvider.name = _newName[i];
            emit DataProviderNameUpdated(_dataProvider[i]);

            unchecked {
                i++;
            }
        }
    }

    function addDataFeeds(address _dataProvider, DataFeed[] calldata _dataFeeds)
        external
        override
        onlyOwner
    {
        uint256 length = _dataFeeds.length;
        for (uint256 i = 0; i < length; ) {
            require(
                bytes(_dataFeeds[i].referenceAsset).length != 0 &&
                    bytes(_dataFeeds[i].referenceAssetUnified).length != 0 &&
                    bytes(_dataFeeds[i].dataSourceLink).length != 0,
                "Whitelist: Invalid inputs"
            );

            dataFeeds[_dataProvider].push(
                DataFeed(
                    _dataFeeds[i].referenceAsset,
                    _dataFeeds[i].referenceAssetUnified,
                    _dataFeeds[i].roundingDecimals,
                    _dataFeeds[i].dataSourceLink,
                    _dataFeeds[i].active
                )
            );
            emit DataFeedAdded(_dataProvider, dataFeeds[_dataProvider].length - 1);

            unchecked {
                i++;
            }
        }
    }

    function deactivateDataFeeds(address _dataProvider, uint256[] calldata _index)
        external
        override
    {
        require(
            msg.sender == _dataProvider || msg.sender == owner(),
            "Whitelist: only owner or data provider"
        );
        uint256 length = _index.length;
        for (uint256 i = 0; i < length; ) {
            dataFeeds[_dataProvider][_index[i]].active = false;
            emit DataFeedDeactivated(_dataProvider, _index[i]);

            unchecked {
                i++;
            }
        }
    }

    function activateDataFeeds(address _dataProvider, uint256[] calldata _index)
        external
        override
        onlyOwner
    {
        uint256 length = _index.length;
        for (uint256 i = 0; i < length; ) {
            dataFeeds[_dataProvider][_index[i]].active = true;
            emit DataFeedActivated(_dataProvider, _index[i]);

            unchecked {
                i++;
            }
        }
    }

    function addCollateralTokens(address[] calldata _collateralToken)
        external
        override
        onlyOwner
    {
        uint256 length = _collateralToken.length;
        for (uint256 i = 0; i < length; ) {
            require(
                _collateralToken[i] != address(0),
                "Whitelist: null address"
            );
            collateralTokens[_collateralToken[i]] = true;
            emit CollateralTokenAdded(_collateralToken[i]);

            unchecked {
                i++;
            }
        }
    }

    function deleteCollateralTokens(address[] calldata _collateralToken)
        external
        override
        onlyOwner
    {
        uint256 length = _collateralToken.length;
        for (uint256 i = 0; i < length; ) {
            delete collateralTokens[_collateralToken[i]];
            emit CollateralTokenDeleted(_collateralToken[i]);

            unchecked {
                i++;
            }
        }
    }

    function getDataProvider(address _dataProvider)
        external
        view
        override
        returns (DataProvider memory)
    {
        return dataProviders[_dataProvider];
    }

    function getDataFeeds(address _dataProvider)
        external
        view
        override
        returns (DataFeed[] memory)
    {
        return dataFeeds[_dataProvider];
    }

    function getDataFeed(address _dataProvider, uint256 _index)
        external
        view
        override
        returns (DataFeed memory)
    {
        return dataFeeds[_dataProvider][_index];
    }

    function getCollateralToken(address _collateralToken)
        external
        view
        override
        returns (bool)
    {
        return collateralTokens[_collateralToken];
    }

    /* 
    Auxiliary function to check whether an entry already exists in the 
    dataProviders mapping. The `addDataProviders` function ensures that 
    every data provider has a name.    
    */
    function _dataProviderExists(address _dataProvider) private view returns (bool) {
        if (bytes(dataProviders[_dataProvider].name).length != 0) {
            return true;
        } else {
            return false;
        }
    }
}

pragma solidity 0.8.4;

/**
 * @title Interface for the Whitelist contract.
 */
interface IWhitelist {
    struct DataProvider {
        string name;
        bool publicTrigger; // 1 if anyone can trigger the oracle to submit the final value, 0 if only the owner of the address can do it 
    }

    struct DataFeed {
        string referenceAsset;
        string referenceAssetUnified;
        uint8 roundingDecimals;
        string dataSourceLink;
        bool active;
    }

    /**
     * @notice Emitted when a new data provider address is added to the
     * whitelist
     * @param providerAddress Data provider address that was added
     */
    event DataProviderAdded(address indexed providerAddress);

    /**
     * @notice Emitted when an existing data provider address is deleted
     * from the whitelist
     * @param providerAddress Data provider address that was removed
     */
    event DataProviderDeleted(address indexed providerAddress);

    /**
     * @notice Emitted when the name attribute of a whitelisted data
     * provider was updated
     * @param providerAddress Data provider address where the name
     * change occured
     */
    event DataProviderNameUpdated(address indexed providerAddress);

    /**
     * @notice Emitted when a new data feed was added for a given
     * data provider address
     * @param providerAddress Data provider address where a new data feed
     * was added
     * @param index Index associated with the new data feed
     */
    event DataFeedAdded(address indexed providerAddress, uint256 indexed index);

    /**
     * @notice Emitted when an existing data feed was deactivated for a given
     * data provider address
     * @param providerAddress Data provider address for which a data feed
     * was deactivated
     * @param index Index associated with the deactivated data feed
     */
    event DataFeedDeactivated(
        address indexed providerAddress,
        uint256 indexed index
    );

    /**
     * @notice Emitted when an existing data feed was activated for a given
     * data provider address
     * @param providerAddress Data provider address for which a data feed
     * was activated
     * @param index Index associated with the activated data feed
     */
    event DataFeedActivated(
        address indexed providerAddress,
        uint256 indexed index
    );

    /**
     * @notice Emitted when a collateral token is added to the whitelist
     * @param collateralToken Collateral token address
     */
    event CollateralTokenAdded(address indexed collateralToken);

    /**
     * @notice Emitted when a collateral token is deleted from the whitelist
     * @param collateralToken Collateral token address
     */
    event CollateralTokenDeleted(address indexed collateralToken);

    /**
     * @notice Function to whitelist a given list of data providers
     * @dev Will revert if any of the provided addresses already exist in
     * the dataProviders mapping or the length of `_dataProvider` and
     * `_dataProviderInfo` array is not the same
     * @param _dataProvider Array of data provider addresses to be added
     * @param _dataProviderInfo Array of corresponding data provider info
     * including `name` and `publicTrigger` flag
     */
    function addDataProviders(address[] calldata _dataProvider, DataProvider[] calldata _dataProviderInfo)
        external;

    /**
     * @notice Function to update the name for a given list of data providers
     * @dev Will revert if a provided address is not part of the
     * dataProviders mapping
     * @param _dataProvider Array of existing data provider addresses
     * @param _newName Array of new names corresponding to the `_dataProvider`
     * array
     */
    function updateDataProviderNames(
        address[] calldata _dataProvider,
        string[] calldata _newName
    ) external;

    /**
     * @notice Function to delete a given list of data providers from the
     * dataProviders mapping
     * @dev Will NOT revert if any of the provided address were not part
     * of the dataProviders mapping
     * @param _dataProvider Array of data provider addresses to be deleted
     */
    function deleteDataProviders(address[] calldata _dataProvider) external;

    /**
     * @notice Function to add a list of data feeds for a given provider
     * address
     * @dev Function does not prevent duplicate entries; caller needs to
     * make sure that no duplicate entries are added.
     * Inactive entries can be added and activated at a later stage via
     * the `activateDataFeeds` function
     * @param _dataProvider Data provider address
     * @param _dataFeeds Array of data feed information. The `active` flag
     * is automatically set to true at execution
     */
    function addDataFeeds(address _dataProvider, DataFeed[] calldata _dataFeeds)
        external;

    /**
     * @notice Function to deactivate a list of data feeds for a given
     * provider address
     * @dev This function can only be called by the owner or the corresponding
     * data provider
     * @param _dataProvider Data provider address
     * @param _index Array of indices to be updated in the dataFeed struct
     * array
     */
    function deactivateDataFeeds(address _dataProvider, uint256[] calldata _index)
        external;

    /**
     * @notice Function to activate a list of existing data feeds for a given
     * provider address
     * @dev This function can only be called by the owner
     * @param _dataProvider Data provider address
     * @param _index Array of indices to be updated
     */
    function activateDataFeeds(address _dataProvider, uint256[] calldata _index)
        external;

    /**
     * @notice Function to whitelist a list of collateral token addresses
     * @param _collateralToken Array of collateral token addresses to be added
     */
    function addCollateralTokens(address[] calldata _collateralToken) external;

    /**
     * @notice Function to delete a list of collateral token addresses from
     * the whitelist
     * @param _collateralToken Array of collateral token addresses to be
     * deleted
     */
    function deleteCollateralTokens(address[] calldata _collateralToken) external;

    /**
     * @notice Function to get the data provider name and whitelist status
     * @dev Returns default values, i.e. "" for `name` and and false for 
     * `publicTrigger`, if `_dataProvider` is not whitelisted
     * @param _dataProvider Address of the data provider to query
     */
    function getDataProvider(address _dataProvider)
        external
        view
        returns (DataProvider memory);

    /**
     * @notice Function to return the data feeds for a given data provider
     * @param _dataProvider Data provider address
     */
    function getDataFeeds(address _dataProvider)
        external
        view
        returns (DataFeed[] memory);

    /**
     * @notice Function to return the data feed at a given index for a given
     * data provider
     * @param _dataProvider Data provider address
     * @param _index Index of the data feed to return
     */
    function getDataFeed(address _dataProvider, uint256 _index)
        external
        view
        returns (DataFeed memory);

    /**
     * @notice Function to return whether a given collateral token
     * address is whitelisted
     * @param _collateralToken Collateral token address
     */
    function getCollateralToken(address _collateralToken)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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