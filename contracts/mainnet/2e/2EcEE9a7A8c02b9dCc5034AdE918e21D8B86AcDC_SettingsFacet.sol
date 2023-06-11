/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/interfaces/IMintFactory.sol

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity 0.8.17;

interface IMintFactory {

    struct TaxHelper {
        string Name;
        address Address;
        uint Index;
    }

    function addTaxHelper(string calldata _name, address _address) external;

    function updateTaxHelper(uint _index, address _address) external;

    function getTaxHelperAddress(uint _index) external view returns(address);

    function getTaxHelpersDataByIndex(uint _index) external view returns(TaxHelper memory);

    function registerToken (address _tokenOwner, address _tokenAddress) external;

    function tokenIsRegistered(address _tokenAddress) external view returns (bool);

    function tokenGeneratorsLength() external view returns (uint256);

    function tokenGeneratorIsAllowed(address _tokenGenerator) external view returns (bool);

    function getFacetHelper() external view returns (address);

    function updateFacetHelper(address _newFacetHelperAddress) external;

    function getFeeHelper() external view returns (address);

    function updateFeeHelper(address _newFeeHelperAddress) external;
    
    function getLosslessController() external view returns (address);

    function updateLosslessController(address _newLosslessControllerAddress) external;
}


// File contracts/interfaces/ITaxHelper.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface ITaxHelper {

    function initiateBuyBackTax(
        address _token,
        address _wallet
    ) external returns (bool);

    function initiateLPTokenTax(        
        address _token,
        address _wallet
    ) external returns (bool);

    function lpTokenHasReserves(address _lpToken) external view returns (bool);

    function createLPToken() external returns (address lpToken);

    function sync(address _lpToken) external;
}


// File contracts/interfaces/IERC20.sol



// File @openzeppelin/contracts/token/ERC20/[email protected]



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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/interfaces/ITaxToken.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


interface ITaxToken is IERC20 {

    function taxHelperIndex()external view returns(uint);

    function buyBackBurn(uint256 _amount) external;

    function owner() external view returns (address);

    function pairAddress() external view returns (address);
    function decimals() external view returns (uint8);

}


// File contracts/libraries/Context.sol

// 

// File @openzeppelin/contracts/utils/[email protected]



/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/libraries/Ownable.sol

// 

// File @openzeppelin/contracts/access/[email protected]


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/BuyBackWallet.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract BuyBackWallet is Ownable{
    

    ITaxToken public token; 
    IMintFactory public factory;
    uint256 private threshold;

    event UpdatedThreshold(uint256 _newThreshold);
    event ETHtoTaxHelper(uint256 amount);


    constructor(address _factory, address _token, uint256 _newThreshold) {
        token = ITaxToken(_token);
        factory = IMintFactory(_factory);
        threshold = _newThreshold;
        emit UpdatedThreshold(_newThreshold);
        transferOwnership(_token);
    }
    
    function checkBuyBackTrigger() public view returns (bool) {
        return address(this).balance > threshold;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendEthToTaxHelper() external returns (uint256) {
        uint index = token.taxHelperIndex();
        require(msg.sender == factory.getTaxHelperAddress(index), "RA");
        uint256 amount = address(this).balance;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit ETHtoTaxHelper(amount);
        return amount;
    }

    function updateThreshold(uint256 _newThreshold) external onlyOwner {
        threshold = _newThreshold;
        emit UpdatedThreshold(_newThreshold);
    }

    function getThreshold() external view returns (uint256) {
        return threshold;
    }

    receive() payable external {
    }
}


// File contracts/FacetHelper.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract FacetHelper is Ownable{

    event AddedFacet(address _newFacet);
    event AddedSelector(address _facet, bytes4 _sig);
    event RemovedSelector(bytes4 _sig);
    event ResetStorage();

    event UpdatedSettingsFacet(address _newAddress);
    event UpdatedLosslessFacet(address _newAddress);
    event UpdatedTaxFacet(address _newAddress);
    event UpdatedConstructorFacet(address _newAddress);
    event UpdatedWalletsFacet(address _newAddress);
    event UpdatedAntiBotFacet(address _newAddress);
    event UpdatedMulticallFacet(address _newAddress);

    struct Facets {
        address Settings;
        address Lossless;
        address Tax;
        address Constructor;
        address Wallets;
        address AntiBot;
        address Multicall;
    }

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) _selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) _facetFunctionSelectors;
    // facet addresses
    address[] _facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;

    Facets public facetsInfo;

    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_) {
        uint256 numFacets = _facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = _facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = _facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {
        facetFunctionSelectors_ = _facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_) {
        facetAddresses_ = _facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {
        facetAddress_ = _selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }

    event DiamondCut(FacetCut[] _diamondCut);

    function diamondCut(
        FacetCut[] memory _diamondCut
    ) public onlyOwner {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(_facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            _facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(_facetAddresses.length);
            _facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            _facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            _selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            _selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(_facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            _facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(_facetAddresses.length);
            _facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            _selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            _facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            _selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            _facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        _facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete _selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = _facetAddresses.length - 1;
            uint256 facetAddressPosition = _facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _facetAddresses[lastFacetAddressPosition];
                _facetAddresses[facetAddressPosition] = lastFacetAddress;
                _facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            _facetAddresses.pop();
            delete _facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    // mapping(bytes4 => address) public selectorToFacet;
    // bytes4[] public selectorsList;
    // mapping(address => bool) public isFacet;
    // address[] public facetsList;

    // function addFacet(address _newFacet) public onlyOwner {
    //     isFacet[_newFacet] = true;
    //     facetsList.push(_newFacet);
    //     emit AddedFacet(_newFacet);
    // }

    // function batchAddSelectors(address _facet, bytes4[] memory _sigs) public onlyOwner {
    //     for(uint256 index; index < _sigs.length; index++) {
    //         addSelector(_facet, _sigs[index]);
    //     }
    // }

    // function addSelector(address _facet, bytes4 _sig) public onlyOwner {
    //     require(selectorToFacet[_sig] == address(0));
    //     // require(isFacet[_facet]);
    //     selectorToFacet[_sig] = _facet;
    //     selectorsList.push(_sig);
    //     emit AddedSelector(_facet, _sig);
    // }

    // Removing of the selectors occurs during resetFacetStorage();
    // it is easier to reset and rebuild using the script when deploying and updating the facets
    // function removeSelector(bytes4 _sig) public onlyOwner {
    //     selectorToFacet[_sig] = address(0);
    //     emit RemovedSelector(_sig);
    // }    

    // function getFacetAddressFromSelector(bytes4 _sig) public view returns (address) {
    //     return selectorToFacet[_sig];
    // }

    // function getFacetByIndex(uint256 _index) public view returns(address) {
    //     return facetsList[_index];
    // }

    // function resetFacetStorage() public onlyOwner {
    //     for(uint i = 0; i < selectorsList.length; i++) {
    //         bytes4 sig = selectorsList[i];
    //         selectorToFacet[sig] = address(0);
    //     }
    //     delete selectorsList;

    //     for(uint i = 0; i < facetsList.length; i++) {
    //         address facet = facetsList[i];
    //         isFacet[facet] = false;
    //     }
    //     delete facetsList;

    //     emit ResetStorage();
    // }

        // Facet getters and setters

    function getSettingsFacet() public view returns (address) {
        return facetsInfo.Settings;
    }

    function updateSettingsFacet(address _newSettingsAddress) public onlyOwner {
        facetsInfo.Settings = _newSettingsAddress;
        emit UpdatedSettingsFacet(_newSettingsAddress);
    }

    function getLosslessFacet() public view returns (address) {
        return facetsInfo.Lossless;
    }

    function updateLosslessFacet(address _newLosslessAddress) public onlyOwner {
        facetsInfo.Lossless = _newLosslessAddress;
        emit UpdatedLosslessFacet(_newLosslessAddress);
    }

    function getTaxFacet() public view returns (address) {
        return facetsInfo.Tax;
    }

    function updateTaxFacet(address _newTaxAddress) public onlyOwner {
        facetsInfo.Tax = _newTaxAddress;
        emit UpdatedTaxFacet(_newTaxAddress);
    }

    function getConstructorFacet() public view returns (address) {
        return facetsInfo.Constructor;
    }

    function updateConstructorFacet(address _newConstructorAddress) public onlyOwner {
        facetsInfo.Constructor = _newConstructorAddress;
        emit UpdatedConstructorFacet(_newConstructorAddress);
    }

    function getWalletsFacet() public view returns (address) {
        return facetsInfo.Wallets;
    }

    function updateWalletsFacet(address _newWalletsAddress) public onlyOwner {
        facetsInfo.Wallets = _newWalletsAddress;
        emit UpdatedWalletsFacet(_newWalletsAddress);
    }

    function getAntiBotFacet() public view returns (address) {
        return facetsInfo.AntiBot;
    }

    function updateAntiBotFacet(address _newAntiBotAddress) public onlyOwner {
        facetsInfo.AntiBot = _newAntiBotAddress;
        emit UpdatedAntiBotFacet(_newAntiBotAddress);
    }

    function getMulticallFacet() public view returns (address) {
        return facetsInfo.Multicall;
    }

    function updateMulticallFacet(address _newWalletsAddress) public onlyOwner {
        facetsInfo.Multicall = _newWalletsAddress;
        emit UpdatedMulticallFacet(_newWalletsAddress);
    }
}


// File contracts/interfaces/ILosslessController.sol

// 



interface ILosslessController {
    
    function pause() external;
    function unpause() external;
    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;

    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;
    function beforeMint(address _to, uint256 _amount) external;
    function beforeBurn(address _account, uint256 _amount) external;
    function afterTransfer(address _sender, address _recipient, uint256 _amount) external;


    event AdminChange(address indexed _newAdmin);
    event RecoveryAdminChange(address indexed _newAdmin);
}


// File contracts/facets/Storage.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


struct Storage {

    uint256 CONTRACT_VERSION;


    TaxSettings taxSettings;
    TaxSettings isLocked;
    Fees fees;
    CustomTax[] customTaxes;

    address transactionTaxWallet;
    uint256 customTaxLength;
    uint256 MaxTax;
    uint8 MaxCustom;

    uint256 DENOMINATOR;

    mapping (address => uint256) _rOwned;
    mapping (address => uint256) _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isExcluded;
    address[] _excluded;
   
    uint256 MAX;
    uint256 _tTotal;
    uint256 _rTotal;
    uint256 _tFeeTotal;

    mapping (address => bool) lpTokens;
    
    string _name;
    string _symbol;
    uint8 _decimals;
    address _creator;

    address factory;

    address buyBackWallet;
    address lpWallet;

    bool isPaused;

    bool isTaxed;
    
    mapping(address => bool) blacklist;
    mapping(address => bool) swapWhitelist;
    mapping(address => bool) maxBalanceWhitelist;
    mapping(address => bool) taxWhitelist;

    address pairAddress;

    uint256 taxHelperIndex;

    // AntiBot Variables

    bool marketInit;
    uint256 marketInitBlockTime;

    AntiBotSettings antiBotSettings;

    mapping (address => uint256) antiBotBalanceTracker;

    uint256 maxBalanceAfterBuy;
    
    SwapWhitelistingSettings swapWhitelistingSettings;

    // Lossless data and events

    address recoveryAdmin;
    address recoveryAdminCandidate;
    bytes32 recoveryAdminKeyHash;
    address admin;
    uint256 timelockPeriod;
    uint256 losslessTurnOffTimestamp;
    bool isLosslessTurnOffProposed;
    bool isLosslessOn;
}

struct TaxSettings {
    bool transactionTax;
    bool buyBackTax;
    bool holderTax;
    bool lpTax;
    bool canBlacklist;
    bool canMint;
    bool canPause;
    bool maxBalanceAfterBuy;
}

struct Fee {
    uint256 buy;
    uint256 sell;
}

struct Fees {
    Fee transactionTax;
    uint256 buyBackTax;
    uint256 holderTax;
    uint256 lpTax;
}

struct CustomTax {
    string name;
    Fee fee;
    address wallet;
    bool withdrawAsGas;
}

struct AntiBotSettings {
    uint256 startBlock;
    uint256 endDate;
    uint256 increment;
    uint256 initialMaxHold;
    bool isActive;
}

struct SwapWhitelistingSettings {
    uint256 endDate;
    bool isActive;
}


// File contracts/facets/AntiBot.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract AntiBotFacet is Ownable {
    Storage internal s;

    event UpdatedAntiBotIncrement(uint256 _updatedIncrement);
    event UpdatedAntiBotEndDate(uint256 _updatedEndDate);
    event UpdatedAntiBotInitialMaxHold(uint256 _updatedInitialMaxHold);
    event UpdatedAntiBotActiveStatus(bool _isActive);
    event UpdatedSwapWhitelistingEndDate(uint256 _updatedEndDate);
    event UpdatedSwapWhitelistingActiveStatus(bool _isActive);
    event UpdatedMaxBalanceAfterBuy(uint256 _newMaxBalance);

    event AddedMaxBalanceWhitelistAddress(address _address);   
    event RemovedMaxBalanceWhitelistAddress(address _address);        
    event AddedSwapWhitelistAddress(address _address);
    event RemovedSwapWhitelistAddress(address _address);
    
    // AntiBot

    function antiBotIsActiveModifier() view internal {
        require(s.antiBotSettings.isActive, "ABD");
    }

    modifier antiBotIsActive() {
        antiBotIsActiveModifier();
        _;
    }

    function setIncrement(uint256 _updatedIncrement) public onlyOwner antiBotIsActive {
        s.antiBotSettings.increment = _updatedIncrement;
        emit UpdatedAntiBotIncrement(_updatedIncrement);
    }

    function setEndDate( uint256 _updatedEndDate) public onlyOwner antiBotIsActive {
        require(_updatedEndDate <= 48, "ED");
        s.antiBotSettings.endDate = _updatedEndDate;
        emit UpdatedAntiBotEndDate(_updatedEndDate);
    }

    function setInitialMaxHold( uint256 _updatedInitialMaxHold) public onlyOwner antiBotIsActive {
        s.antiBotSettings.initialMaxHold = _updatedInitialMaxHold;
        emit UpdatedAntiBotInitialMaxHold(_updatedInitialMaxHold);
    }

    function updateAntiBot(bool _isActive) public onlyOwner {
        require(!s.marketInit, "AMIE");
        s.antiBotSettings.isActive = _isActive;
        emit UpdatedAntiBotActiveStatus(_isActive);
    }

    function antiBotCheck(uint256 amount, address receiver) public returns(bool) {
        // restrict it to being only called by registered tokens
        require(IMintFactory(s.factory).tokenIsRegistered(address(this)));
        require(s.marketInit, "AMIE");
        if(block.timestamp > s.marketInitBlockTime + (s.antiBotSettings.endDate * 1 hours)) {
            s.antiBotSettings.isActive = false;
            return true;
        }

        s.antiBotBalanceTracker[receiver] += amount;
        uint256 userAntiBotBalance = s.antiBotBalanceTracker[receiver];
        uint256 maxAntiBotBalance = ((block.number - s.antiBotSettings.startBlock) * s.antiBotSettings.increment) + s.antiBotSettings.initialMaxHold;

        require((userAntiBotBalance <= maxAntiBotBalance), "ABMSA");
        return true;
    }

    // MaxBalanceAfterBuy
   
    function addMaxBalanceWhitelistedAddress(address _address) public onlyOwner {
        require(s.taxSettings.maxBalanceAfterBuy, "AMBABD");
        s.maxBalanceWhitelist[_address] = true;
        emit AddedMaxBalanceWhitelistAddress(_address);
    }

    function removeMaxBalanceWhitelistedAddress(address _address) public onlyOwner {
        require(s.taxSettings.maxBalanceAfterBuy, "AMBABD");
        s.maxBalanceWhitelist[_address] = false;
        emit RemovedMaxBalanceWhitelistAddress(_address);
    }

    function updateMaxBalanceWhitelistBatch(address[] calldata _updatedAddresses, bool _isMaxBalanceWhitelisted) public onlyOwner {
        require(s.taxSettings.maxBalanceAfterBuy, "AMBABD");
        for(uint i = 0; i < _updatedAddresses.length; i++) {
            s.maxBalanceWhitelist[_updatedAddresses[i]] = _isMaxBalanceWhitelisted;
            if(_isMaxBalanceWhitelisted) {
                emit AddedMaxBalanceWhitelistAddress(_updatedAddresses[i]);
            } else {
                emit RemovedMaxBalanceWhitelistAddress(_updatedAddresses[i]);
            }
        }
    }

    function isMaxBalanceWhitelisted(address _address) public view returns (bool) {
        return s.maxBalanceWhitelist[_address];
    }

    function updateMaxBalanceAfterBuy(uint256 _updatedMaxBalanceAfterBuy) public onlyOwner {
        require(s.taxSettings.maxBalanceAfterBuy, "AMBABD");
        s.maxBalanceAfterBuy = _updatedMaxBalanceAfterBuy;
        emit UpdatedMaxBalanceAfterBuy(_updatedMaxBalanceAfterBuy);
    }

    function maxBalanceAfterBuyCheck(uint256 amount, address receiver) public view returns(bool) {
        if(s.maxBalanceWhitelist[receiver]) {
            return true;
        }
        require(s.taxSettings.maxBalanceAfterBuy);
        uint256 receiverBalance;
        if(s.taxSettings.holderTax) {
            receiverBalance = s._rOwned[receiver];
        } else {
            receiverBalance = s._tOwned[receiver];
        }
        receiverBalance += amount;
        require(receiverBalance <= s.maxBalanceAfterBuy, "MBAB");
        return true;
    }

    // SwapWhitelist

    function addSwapWhitelistedAddress(address _address) public onlyOwner {
        require(s.swapWhitelistingSettings.isActive, "ASWD");
        s.swapWhitelist[_address] = true;
        emit AddedSwapWhitelistAddress(_address);
    }

    function removeSwapWhitelistedAddress(address _address) public onlyOwner {
        require(s.swapWhitelistingSettings.isActive, "ASWD");
        s.swapWhitelist[_address] = false;
        emit RemovedSwapWhitelistAddress(_address);
    }

    function updateSwapWhitelistBatch(address[] calldata _updatedAddresses, bool _isSwapWhitelisted) public onlyOwner {
        require(s.swapWhitelistingSettings.isActive, "ASWD");
        for(uint i = 0; i < _updatedAddresses.length; i++) {
            s.swapWhitelist[_updatedAddresses[i]] = _isSwapWhitelisted;
            if(_isSwapWhitelisted) {
                emit AddedSwapWhitelistAddress(_updatedAddresses[i]);
            } else {
                emit RemovedSwapWhitelistAddress(_updatedAddresses[i]);
            }
        }
    }

    function isSwapWhitelisted(address _address) public view returns (bool) {
        return s.swapWhitelist[_address];
    }

    function setSwapWhitelistEndDate( uint256 _updatedEndDate) public onlyOwner {
        require(s.swapWhitelistingSettings.isActive, "ASWD");
        require(_updatedEndDate <= 48, "ED");
        s.swapWhitelistingSettings.endDate = _updatedEndDate;
        emit UpdatedSwapWhitelistingEndDate(_updatedEndDate);
    }

    function updateSwapWhitelisting(bool _isActive) public onlyOwner {
        require(!s.marketInit, "AMIE");
        s.swapWhitelistingSettings.isActive = _isActive;
        emit UpdatedSwapWhitelistingActiveStatus(_isActive);
    }

    function swapWhitelistingCheck(address receiver) public returns(bool) {
        require(s.marketInit, "AMIE");
        if(block.timestamp > s.marketInitBlockTime + (s.swapWhitelistingSettings.endDate * 1 hours)) {
            s.swapWhitelistingSettings.isActive = false;
            return true;
        }
        require(s.swapWhitelist[receiver], "SWL");
        return true;
    }
}


// File contracts/interfaces/IBuyBackWallet.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface IBuyBackWallet {

    function checkBuyBackTrigger() external view returns (bool);

    function getBalance() external view returns (uint256);

    function sendEthToTaxHelper() external returns(uint256);

    function updateThreshold(uint256 _newThreshold) external;

    function getThreshold() external view returns (uint256);
}


// File contracts/interfaces/IFacetHelper.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface IFacetHelper {

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
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);

    // function addFacet(address _newFacet) external;

    // function addSelector(address _facet, bytes4 _sig) external;

    // function removeSelector(bytes4 _sig) external;

    function getFacetAddressFromSelector(bytes4 _sig) external view returns (address);

    function getSettingsFacet() external view returns (address);

    function updateSettingsFacet(address _newSettingsAddress) external;

    function getTaxFacet() external view returns (address);

    function updateTaxFacet(address _newTaxesAddress) external;

    function getLosslessFacet() external view returns (address);

    function updateLosslessFacet(address _newLosslessAddress) external;

    function getConstructorFacet() external view returns (address);

    function updateConstructorFacet(address _newConstructorAddress) external;

    function getWalletsFacet() external view returns (address);

    function updateWalletsFacet(address _newWalletsAddress) external;

    function getAntiBotFacet() external view returns (address);

    function updateAntiBotFacet(address _newWalletsAddress) external;

    function getMulticallFacet() external view returns (address);

    function updateMulticallFacet(address _newWalletsAddress) external;
    
}


// File contracts/interfaces/ILPWallet.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface ILPWallet {

    function checkLPTrigger() external view returns (bool);

    function getBalance() external view returns (uint256);

    function sendEthToTaxHelper() external returns(uint256);

    function transferBalanceToTaxHelper() external;

    function updateThreshold(uint256 _newThreshold) external;

    function getThreshold() external view returns (uint256);
}


// File contracts/interfaces/ISettings.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface ISettingsFacet {

    function getFacetAddressFromSelector(bytes4 _sig) external view returns (address);
    function createBuyBackWallet(address _factory, address _token) external returns (address);
    function createLPWallet(address _factory, address _token) external returns (address);
}


// File contracts/interfaces/IWallets.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface IWalletsFacet {

    function createBuyBackWallet(address _factory, address _token, uint256 _newThreshold) external returns (address);
    function createLPWallet(address _factory, address _token, uint256 _newThreshold) external returns (address);

    function updateBuyBackWalletThreshold(uint256 _newThreshold) external;

    function updateLPWalletThreshold(uint256 _newThreshold) external;
}


// File contracts/facets/Constructor.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract ConstructorFacet is Ownable {
    Storage internal s;

    event ExcludedAccount(address account);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event UpdatedCustomTaxes(CustomTax[] _customTaxes);
    event UpdatedTaxFees(Fees _updatedFees);
    event UpdatedTransactionTaxAddress(address _newAddress);
    event UpdatedLockedSettings(TaxSettings _updatedLocks);
    event UpdatedSettings(TaxSettings _updatedSettings);
    event UpdatedTaxHelperIndex(uint _newIndex);
    event UpdatedAntiBotSettings(AntiBotSettings _antiBotSettings);
    event UpdatedSwapWhitelistingSettings(SwapWhitelistingSettings _swapWhitelistingSettings);
    event UpdatedMaxBalanceAfterBuy(uint256 _newMaxBalance);
    event AddedLPToken(address _newLPToken);
    event TokenCreated(string name, string symbol, uint8 decimals, uint256 totalSupply, uint256 reflectionTotalSupply);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    struct ConstructorParams {
        string name_; 
        string symbol_; 
        uint8 decimals_; 
        address creator_; 
        uint256 tTotal_;
        uint256 _maxTax;
        TaxSettings _settings;
        TaxSettings _lockedSettings;
        Fees _fees;
        address _transactionTaxWallet;
        CustomTax[] _customTaxes;
        uint256 lpWalletThreshold;
        uint256 buyBackWalletThreshold;
        uint256 _taxHelperIndex;
        address admin_; 
        address recoveryAdmin_; 
        bool isLossless_;
        AntiBotSettings _antiBotSettings;
        uint256 _maxBalanceAfterBuy;
        SwapWhitelistingSettings _swapWhitelistingSettings;
    }

    function constructorHandler(ConstructorParams calldata params, address _factory) external {
        require(IMintFactory(_factory).tokenGeneratorIsAllowed(msg.sender), "RA");
        require(params.creator_ != address(0), "ZA");
        require(params._transactionTaxWallet != address(0), "ZA");
        require(params.admin_ != address(0), "ZA");
        require(params.recoveryAdmin_ != address(0), "ZA");
        require(_factory != address(0), "ZA");

        // Set inital values
        s.CONTRACT_VERSION = 1;
        s.customTaxLength = 0;
        s.MaxTax = 3000;
        s.MaxCustom = 10;
        s.MAX = ~uint256(0);
        s.isPaused = false;
        s.isTaxed = false;
        s.marketInit = false;

        s._name = params.name_;
        s._symbol = params.symbol_;
        s._decimals = params.decimals_;
        s._creator = params.creator_;
        s._isExcluded[params.creator_] = true;
        s._excluded.push(params.creator_);
        emit ExcludedAccount(s._creator);
        // Lossless
        s.isLosslessOn = params.isLossless_;
        s.admin = params.admin_;
        emit AdminChanged(address(0), s.admin);
        s.recoveryAdmin = params.recoveryAdmin_;
        emit RecoveryAdminChanged(address(0), s.recoveryAdmin);
        s.timelockPeriod = 7 days;
        address lossless = IMintFactory(_factory).getLosslessController();
        s._isExcluded[lossless] = true;
        s._excluded.push(lossless);
        emit ExcludedAccount(lossless);
        // Tax Settings
        require(params._maxTax <= s.MaxTax, "MT");
        s.MaxTax = params._maxTax;
        s.taxSettings = params._settings;
        emit UpdatedSettings(s.taxSettings);
        s.isLocked = params._lockedSettings;
        s.isLocked.holderTax = true;
        if(s.taxSettings.holderTax) {
            s.taxSettings.canMint = false;
            s.isLocked.canMint = true;
        }
        emit UpdatedLockedSettings(s.isLocked);
        s.fees = params._fees;
        emit UpdatedTaxFees(s.fees);
        require(params._customTaxes.length < s.MaxCustom + 1, "MCT");
        for(uint i = 0; i < params._customTaxes.length; i++) {
            require(params._customTaxes[i].wallet != address(0));
            s.customTaxes.push(params._customTaxes[i]);
        }
        emit UpdatedCustomTaxes(s.customTaxes);
        s.customTaxLength = params._customTaxes.length;
        s.transactionTaxWallet = params._transactionTaxWallet;
        emit UpdatedTransactionTaxAddress(s.transactionTaxWallet);
        // Factory, Wallets, Pair Address
        s.factory = _factory;
        s.taxHelperIndex = params._taxHelperIndex;
        emit UpdatedTaxHelperIndex(s.taxHelperIndex);
        address taxHelper = IMintFactory(s.factory).getTaxHelperAddress(s.taxHelperIndex);
        s.pairAddress = ITaxHelper(taxHelper).createLPToken();
        addLPToken(s.pairAddress);
        address wallets = IFacetHelper(IMintFactory(s.factory).getFacetHelper()).getWalletsFacet(); 
        s.buyBackWallet = IWalletsFacet(wallets).createBuyBackWallet(s.factory, address(this), params.buyBackWalletThreshold);
        s.lpWallet = IWalletsFacet(wallets).createLPWallet(s.factory, address(this), params.lpWalletThreshold);
        // Total Supply and other info
        s._rTotal = (s.MAX - (s.MAX % params.tTotal_));
        s._rOwned[params.creator_] = s._rTotal;
        s.DENOMINATOR = 10000;
        s._isExcluded[taxHelper] = true;
        s._excluded.push(taxHelper);
        emit ExcludedAccount(taxHelper);
        require(checkMaxTax(true), "BF");
        require(checkMaxTax(false), "SF");
        transferOwnership(params.creator_);
        _mintInitial(params.creator_, params.tTotal_);
        // AntiBot Settings
        require(params._antiBotSettings.endDate <= 48, "ED");
        require(params._swapWhitelistingSettings.endDate <= 48, "ED");
        s.antiBotSettings = params._antiBotSettings;
        emit UpdatedAntiBotSettings(s.antiBotSettings);
        s.maxBalanceAfterBuy = params._maxBalanceAfterBuy;
        emit UpdatedMaxBalanceAfterBuy(s.maxBalanceAfterBuy);
        s.swapWhitelistingSettings = params._swapWhitelistingSettings;
        emit UpdatedSwapWhitelistingSettings(s.swapWhitelistingSettings);
        emit TokenCreated(s._name, s._symbol, s._decimals, s._tTotal, s._rTotal);
    }

    function _mintInitial(address account, uint256 amount) internal virtual {
        s._tTotal += amount;
        s._tOwned[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function checkMaxTax(bool isBuy) internal view returns (bool) {
        uint256 totalTaxes;
        if(isBuy) {
            totalTaxes += s.fees.transactionTax.buy;
            totalTaxes += s.fees.holderTax;
            for(uint i = 0; i < s.customTaxes.length; i++) {
                totalTaxes += s.customTaxes[i].fee.buy;
            }
        } else {
            totalTaxes += s.fees.transactionTax.sell;
            totalTaxes += s.fees.lpTax;
            totalTaxes += s.fees.holderTax;
            totalTaxes += s.fees.buyBackTax;
            for(uint i = 0; i < s.customTaxes.length; i++) {
                totalTaxes += s.customTaxes[i].fee.sell;
            }
        }
        if(totalTaxes <= s.MaxTax) {
            return true;
        }
        return false;
    }


    function addLPToken(address _newLPToken) internal {
        s.lpTokens[_newLPToken] = true;
        emit AddedLPToken(_newLPToken);
    }
}


// File contracts/facets/Lossless.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract LosslessFacet is Ownable {
    Storage internal s;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChangeProposed(address indexed candidate);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event LosslessTurnOffProposed(uint256 turnOffDate);
    event LosslessTurnedOff();
    event LosslessTurnedOn();

    function onlyRecoveryAdminCheck() internal view {
        require(_msgSender() == s.recoveryAdmin, "LRA");
    }

    modifier onlyRecoveryAdmin() {
        onlyRecoveryAdminCheck();
        _;
    }

    // --- LOSSLESS management ---

    function getAdmin() external view returns (address) {
        return s.admin;
    }

    function setLosslessAdmin(address newAdmin) external onlyRecoveryAdmin {
        require(newAdmin != address(0), "LZ");
        emit AdminChanged(s.admin, newAdmin);
        s.admin = newAdmin;
    }

    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) external onlyRecoveryAdmin {
        require(candidate != address(0), "LZ");
        s.recoveryAdminCandidate = candidate;
        s.recoveryAdminKeyHash = keyHash;
        emit RecoveryAdminChangeProposed(candidate);
    }

    function acceptRecoveryAdminOwnership(bytes memory key) external {
        require(_msgSender() == s.recoveryAdminCandidate, "LC");
        require(keccak256(key) == s.recoveryAdminKeyHash, "LIK");
        emit RecoveryAdminChanged(s.recoveryAdmin, s.recoveryAdminCandidate);
        s.recoveryAdmin = s.recoveryAdminCandidate;
    }

    function proposeLosslessTurnOff() external onlyRecoveryAdmin {
        s.losslessTurnOffTimestamp = block.timestamp + s.timelockPeriod;
        s.isLosslessTurnOffProposed = true;
        emit LosslessTurnOffProposed(s.losslessTurnOffTimestamp);
    }

    function executeLosslessTurnOff() external onlyRecoveryAdmin {
        require(s.isLosslessTurnOffProposed, "LTNP");
        require(s.losslessTurnOffTimestamp <= block.timestamp, "LTL");
        s.isLosslessOn = false;
        s.isLosslessTurnOffProposed = false;
        emit LosslessTurnedOff();
    }

    function executeLosslessTurnOn() external onlyRecoveryAdmin {
        s.isLosslessTurnOffProposed = false;
        s.isLosslessOn = true;
        emit LosslessTurnedOn();
    }
}


// File contracts/facets/Multicall.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract MulticallFacet is Ownable {
    Storage internal s;

    event UpdatedSettings(TaxSettings _updatedSettings);
    event UpdatedLockedSettings(TaxSettings _updatedLocks);
    event UpdatedCustomTaxes(CustomTax[] _customTaxes);
    event UpdatedTaxFees(Fees _updatedFees);
    event UpdatedTransactionTaxAddress(address _newAddress);
    event UpdatedMaxBalanceAfterBuy(uint256 _newMaxBalance);
    event UpdatedBuyBackWalletThreshold(uint256 _newThreshold);
    event UpdatedLPWalletThreshold(uint256 _newThreshold);
    event UpdatedAntiBotIncrement(uint256 _updatedIncrement);
    event UpdatedAntiBotEndDate(uint256 _updatedEndDate);
    event UpdatedAntiBotInitialMaxHold(uint256 _updatedInitialMaxHold);
    event UpdatedAntiBotActiveStatus(bool _isActive);
    event UpdatedSwapWhitelistingEndDate(uint256 _updatedEndDate);
    event UpdatedSwapWhitelistingActiveStatus(bool _isActive);

    struct MulticallAdminUpdateParams {
        TaxSettings _taxSettings;
        TaxSettings _lockSettings;
        CustomTax[] _customTaxes;
        Fees _fees;
        address _transactionTaxWallet;
        uint256 _maxBalanceAfterBuy;
        uint256 _lpWalletThreshold;
        uint256 _buyBackWalletThreshold;
    }

    function multicallAdminUpdate(MulticallAdminUpdateParams calldata params) public onlyOwner {
        // Tax Settings
        if(!s.isLocked.transactionTax && s.taxSettings.transactionTax != params._taxSettings.transactionTax) {
            s.taxSettings.transactionTax = params._taxSettings.transactionTax;
        }
        if(!s.isLocked.holderTax && s.taxSettings.holderTax != params._taxSettings.holderTax && !params._taxSettings.canMint) {
            s.taxSettings.holderTax = params._taxSettings.holderTax;
        }
        if(!s.isLocked.buyBackTax && s.taxSettings.buyBackTax != params._taxSettings.buyBackTax) {
            s.taxSettings.buyBackTax = params._taxSettings.buyBackTax;
        }
        if(!s.isLocked.lpTax && s.taxSettings.lpTax != params._taxSettings.lpTax) {
            s.taxSettings.lpTax = params._taxSettings.lpTax;
        }
        if(!s.isLocked.canMint && s.taxSettings.canMint != params._taxSettings.canMint && !s.taxSettings.holderTax) {
            s.taxSettings.canMint = params._taxSettings.canMint;
        }
        if(!s.isLocked.canPause && s.taxSettings.canPause != params._taxSettings.canPause) {
            s.taxSettings.canPause = params._taxSettings.canPause;
        }
        if(!s.isLocked.canBlacklist && s.taxSettings.canBlacklist != params._taxSettings.canBlacklist) {
            s.taxSettings.canBlacklist = params._taxSettings.canBlacklist;
        }
        if(!s.isLocked.maxBalanceAfterBuy && s.taxSettings.maxBalanceAfterBuy != params._taxSettings.maxBalanceAfterBuy) {
            s.taxSettings.maxBalanceAfterBuy = params._taxSettings.maxBalanceAfterBuy;
        }
        emit UpdatedSettings(s.taxSettings);


        // Lock Settings
        if(!s.isLocked.transactionTax) {
            s.isLocked.transactionTax = params._lockSettings.transactionTax;
        }
        if(!s.isLocked.holderTax) {
            s.isLocked.holderTax = params._lockSettings.holderTax;
        }
        if(!s.isLocked.buyBackTax) {
            s.isLocked.buyBackTax = params._lockSettings.buyBackTax;
        }
        if(!s.isLocked.lpTax) {
            s.isLocked.lpTax = params._lockSettings.lpTax;
        }
        if(!s.isLocked.canMint) {
            s.isLocked.canMint = params._lockSettings.canMint;
        }
        if(!s.isLocked.canPause) {
            s.isLocked.canPause = params._lockSettings.canPause;
        }
        if(!s.isLocked.canBlacklist) {
            s.isLocked.canBlacklist = params._lockSettings.canBlacklist;
        }
        if(!s.isLocked.maxBalanceAfterBuy) {
            s.isLocked.maxBalanceAfterBuy = params._lockSettings.maxBalanceAfterBuy;
        }
        emit UpdatedLockedSettings(s.isLocked);


        // Custom Taxes
        require(params._customTaxes.length < s.MaxCustom + 1, "MCT");
        delete s.customTaxes;

        for(uint i = 0; i < params._customTaxes.length; i++) {
            require(params._customTaxes[i].wallet != address(0), "ZA");
            s.customTaxes.push(params._customTaxes[i]);
        }
        s.customTaxLength = params._customTaxes.length;
        emit UpdatedCustomTaxes(params._customTaxes);

        // Fees        
        s.fees.transactionTax.buy = params._fees.transactionTax.buy;
        s.fees.transactionTax.sell = params._fees.transactionTax.sell;

        s.fees.buyBackTax = params._fees.buyBackTax;

        s.fees.holderTax = params._fees.holderTax;

        s.fees.lpTax = params._fees.lpTax;

        require(checkMaxTax(true), "BF");
        require(checkMaxTax(false), "SF");
        emit UpdatedTaxFees(params._fees);
        
        // transactionTax address
        require(params._transactionTaxWallet != address(0), "ZA");
        s.transactionTaxWallet = params._transactionTaxWallet;
        emit UpdatedTransactionTaxAddress(params._transactionTaxWallet);

        // maxBalanceAfterBuy
        if(s.taxSettings.maxBalanceAfterBuy) {
            s.maxBalanceAfterBuy = params._maxBalanceAfterBuy;
            emit UpdatedMaxBalanceAfterBuy(params._maxBalanceAfterBuy);
        }

        // update wallet thresholds
        ILPWallet(s.lpWallet).updateThreshold(params._lpWalletThreshold);
        emit UpdatedLPWalletThreshold(params._lpWalletThreshold);

        IBuyBackWallet(s.buyBackWallet).updateThreshold(params._buyBackWalletThreshold);
        emit UpdatedBuyBackWalletThreshold(params._buyBackWalletThreshold);
    }

    function checkMaxTax(bool isBuy) internal view returns (bool) {
        uint256 totalTaxes;
        if(isBuy) {
            totalTaxes += s.fees.transactionTax.buy;
            totalTaxes += s.fees.holderTax;
            for(uint i = 0; i < s.customTaxes.length; i++) {
                totalTaxes += s.customTaxes[i].fee.buy;
            }
        } else {
            totalTaxes += s.fees.transactionTax.sell;
            totalTaxes += s.fees.lpTax;
            totalTaxes += s.fees.holderTax;
            totalTaxes += s.fees.buyBackTax;
            for(uint i = 0; i < s.customTaxes.length; i++) {
                totalTaxes += s.customTaxes[i].fee.sell;
            }
        }
        if(totalTaxes <= s.MaxTax) {
            return true;
        }
        return false;
    }

    struct AntiBotUpdateParams {
        AntiBotSettings _antiBotSettings;
        SwapWhitelistingSettings _swapWhitelistingSettings;
    }

    // Multicall AntiBot Update
    function multicallAntiBotUpdate(AntiBotUpdateParams calldata params) public onlyOwner {
        // AntiBot
        s.antiBotSettings.increment = params._antiBotSettings.increment;
        emit UpdatedAntiBotIncrement(s.antiBotSettings.increment);

        require(params._antiBotSettings.endDate <= 48, "ED");
        s.antiBotSettings.endDate = params._antiBotSettings.endDate;
        emit UpdatedAntiBotEndDate(s.antiBotSettings.endDate);

        s.antiBotSettings.initialMaxHold = params._antiBotSettings.initialMaxHold;
        emit UpdatedAntiBotInitialMaxHold(s.antiBotSettings.initialMaxHold);

        if(!s.marketInit) {
            s.antiBotSettings.isActive = params._antiBotSettings.isActive;
            emit UpdatedAntiBotActiveStatus(s.antiBotSettings.isActive);
        }

        // SwapWhitelisting
        require(params._swapWhitelistingSettings.endDate <= 48, "ED");
        s.swapWhitelistingSettings.endDate = params._swapWhitelistingSettings.endDate;
        emit UpdatedSwapWhitelistingEndDate(s.antiBotSettings.endDate);

        if(!s.marketInit) {
            s.swapWhitelistingSettings.isActive = params._swapWhitelistingSettings.isActive;
            emit UpdatedSwapWhitelistingActiveStatus(s.swapWhitelistingSettings.isActive);
        }
    }
}


// File contracts/interfaces/IFeeHelper.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



interface IFeeHelper {
    function getFee() view external returns(uint256);
    
    function getFeeDenominator() view external returns(uint256);
    
    function setFee(uint _fee) external;
    
    function getFeeAddress() view external returns(address);
    
    function setFeeAddress(address payable _feeAddress) external;

    function getGeneratorFee() view external returns(uint256);

    function setGeneratorFee(uint256 _fee) external;
}


// File contracts/LPWallet.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



contract LPWallet is Ownable{

    ITaxToken public token;
    IMintFactory public factory;
    uint256 private threshold;

    event UpdatedThreshold(uint256 _newThreshold);
    event ETHtoTaxHelper(uint256 amount);
    event TransferBalancetoTaxHelper(uint256 tokenBalance);

    constructor(address _factory, address _token, uint256 _newThreshold) {
        token = ITaxToken(_token);
        factory = IMintFactory(_factory);
        threshold = _newThreshold;
        emit UpdatedThreshold(_newThreshold);
        transferOwnership(_token);
    }
    
    function checkLPTrigger() public view returns (bool) {
        return address(this).balance > threshold;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendEthToTaxHelper() external returns (uint256) {
        uint index = token.taxHelperIndex();
        require(msg.sender == factory.getTaxHelperAddress(index), "RA");
        uint256 amount = address(this).balance;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit ETHtoTaxHelper(amount);
        return amount;
    }

    function transferBalanceToTaxHelper() external {
        uint index = token.taxHelperIndex();
        require(msg.sender == factory.getTaxHelperAddress(index));
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
        emit TransferBalancetoTaxHelper(tokenBalance);
    }

    function updateThreshold(uint256 _newThreshold) external onlyOwner {
        threshold = _newThreshold;
        emit UpdatedThreshold(_newThreshold);
    }

    function getThreshold() external view returns (uint256) {
        return threshold;
    }

    receive() payable external {
    }


}


// File contracts/facets/Settings.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract SettingsFacet is Ownable {
    Storage internal s;

    event AddedLPToken(address _newLPToken);
    event RemovedLPToken(address _lpToken);
    event AddedBlacklistAddress(address _address);
    event RemovedBlacklistAddress(address _address);
    event ToggledPause(bool _isPaused);
    event UpdatedCustomTaxes(CustomTax[] _customTaxes);
    event UpdatedTaxFees(Fees _updatedFees);
    event UpdatedTransactionTaxAddress(address _newAddress);
    event UpdatedLockedSettings(TaxSettings _updatedLocks);
    event UpdatedSettings(TaxSettings _updatedSettings);
    event UpdatedPairAddress(address _newPairAddress);
    event UpdatedTaxHelperIndex(uint _newIndex);
    event AddedTaxWhitelistAddress(address _address);   
    event RemovedTaxWhitelistAddress(address _address);

    function canBlacklistRequire() internal view {
        require(s.taxSettings.canBlacklist, "NB");
    }

    modifier canBlacklist {
        canBlacklistRequire();
        _;
    }

    function addLPToken(address _newLPToken) public onlyOwner {
        s.lpTokens[_newLPToken] = true;
        emit AddedLPToken(_newLPToken);
    }

    function removeLPToken(address _lpToken) public onlyOwner {
        s.lpTokens[_lpToken] = false;
        emit RemovedLPToken(_lpToken);
    }

    function checkMaxTax(bool isBuy) internal view returns (bool) {
        uint256 totalTaxes;
        if(isBuy) {
            totalTaxes += s.fees.transactionTax.buy;
            totalTaxes += s.fees.holderTax;
            for(uint i = 0; i < s.customTaxes.length; i++) {
                totalTaxes += s.customTaxes[i].fee.buy;
            }
        } else {
            totalTaxes += s.fees.transactionTax.sell;
            totalTaxes += s.fees.lpTax;
            totalTaxes += s.fees.holderTax;
            totalTaxes += s.fees.buyBackTax;
            for(uint i = 0; i < s.customTaxes.length; i++) {
                totalTaxes += s.customTaxes[i].fee.sell;
            }
        }
        if(totalTaxes <= s.MaxTax) {
            return true;
        }
        return false;
    }

    function paused() public view returns (bool) {
        if(s.taxSettings.canPause == false) {
            return false;
        }
        return s.isPaused;
    }

    function togglePause() public onlyOwner returns (bool) {
        require(s.taxSettings.canPause, "NP");
        s.isPaused = !s.isPaused;
        emit ToggledPause(s.isPaused);
        return s.isPaused;
    }

    function addBlacklistedAddress(address _address) public onlyOwner canBlacklist {
        IFeeHelper feeHelper = IFeeHelper(IMintFactory(s.factory).getFeeHelper());
        address feeAddress = feeHelper.getFeeAddress();
        require(_address != feeAddress);
        s.blacklist[_address] = true;
        emit AddedBlacklistAddress(_address);
    }

    function removeBlacklistedAddress(address _address) public onlyOwner canBlacklist {
        s.blacklist[_address] = false;
        emit RemovedBlacklistAddress(_address);
    }

    function updateBlacklistBatch(address[] calldata _updatedAddresses, bool _isBlacklisted) public onlyOwner canBlacklist {
        IFeeHelper feeHelper = IFeeHelper(IMintFactory(s.factory).getFeeHelper());
        address feeAddress = feeHelper.getFeeAddress();
        for(uint i = 0; i < _updatedAddresses.length; i++) {
            if(_updatedAddresses[i] != feeAddress) {
                s.blacklist[_updatedAddresses[i]] = _isBlacklisted;
                if(_isBlacklisted) {
                    emit AddedBlacklistAddress(_updatedAddresses[i]);
                } else {
                    emit RemovedBlacklistAddress(_updatedAddresses[i]);
                }
            }
        }
    }

    function isBlacklisted(address _address) public view returns (bool) {
        return s.blacklist[_address];
    }

    function updateCustomTaxes(CustomTax[] calldata _customTaxes) public onlyOwner {
        require(_customTaxes.length < s.MaxCustom + 1, "MCT");
        delete s.customTaxes;

        for(uint i = 0; i < _customTaxes.length; i++) {
            require(_customTaxes[i].wallet != address(0));
            s.customTaxes.push(_customTaxes[i]);
        }
        s.customTaxLength = _customTaxes.length;

        require(checkMaxTax(true), "BF");
        require(checkMaxTax(false), "SF");
        emit UpdatedCustomTaxes(_customTaxes);
    }

    function updateTaxFees(Fees calldata _updatedFees) public onlyOwner {
        s.fees.transactionTax.buy = _updatedFees.transactionTax.buy;
        s.fees.transactionTax.sell = _updatedFees.transactionTax.sell;

        s.fees.buyBackTax = _updatedFees.buyBackTax;

        s.fees.holderTax = _updatedFees.holderTax;

        s.fees.lpTax = _updatedFees.lpTax;

        require(checkMaxTax(true), "BF");
        require(checkMaxTax(false), "SF");
        emit UpdatedTaxFees(_updatedFees);
    }

    function updateTransactionTaxAddress(address _newAddress) public onlyOwner {
        // confirm if this is updateable
        require(_newAddress != address(0));
        s.transactionTaxWallet = _newAddress;
        emit UpdatedTransactionTaxAddress(_newAddress);
    }

    function lockSettings(TaxSettings calldata _updatedLocks) public onlyOwner {
        if(!s.isLocked.transactionTax) {
            s.isLocked.transactionTax = _updatedLocks.transactionTax;
        }
        if(!s.isLocked.holderTax) {
            s.isLocked.holderTax = _updatedLocks.holderTax;
        }
        if(!s.isLocked.buyBackTax) {
            s.isLocked.buyBackTax = _updatedLocks.buyBackTax;
        }
        if(!s.isLocked.lpTax) {
            s.isLocked.lpTax = _updatedLocks.lpTax;
        }
        if(!s.isLocked.canMint) {
            s.isLocked.canMint = _updatedLocks.canMint;
        }
        if(!s.isLocked.canPause) {
            s.isLocked.canPause = _updatedLocks.canPause;
        }
        if(!s.isLocked.canBlacklist) {
            s.isLocked.canBlacklist = _updatedLocks.canBlacklist;
        }
        if(!s.isLocked.maxBalanceAfterBuy) {
            s.isLocked.maxBalanceAfterBuy = _updatedLocks.maxBalanceAfterBuy;
        }
        emit UpdatedLockedSettings(s.isLocked);
    }

    function updateSettings(TaxSettings calldata _updatedSettings) public onlyOwner {
        if(!s.isLocked.transactionTax && s.taxSettings.transactionTax != _updatedSettings.transactionTax) {
            s.taxSettings.transactionTax = _updatedSettings.transactionTax;
        }
        if(!s.isLocked.holderTax && s.taxSettings.holderTax != _updatedSettings.holderTax && !_updatedSettings.canMint) {
            s.taxSettings.holderTax = _updatedSettings.holderTax;
        }
        if(!s.isLocked.buyBackTax && s.taxSettings.buyBackTax != _updatedSettings.buyBackTax) {
            s.taxSettings.buyBackTax = _updatedSettings.buyBackTax;
        }
        if(!s.isLocked.lpTax && s.taxSettings.lpTax != _updatedSettings.lpTax) {
            s.taxSettings.lpTax = _updatedSettings.lpTax;
        }
        if(!s.isLocked.canMint && s.taxSettings.canMint != _updatedSettings.canMint && !s.taxSettings.holderTax) {
            s.taxSettings.canMint = _updatedSettings.canMint;
        }
        if(!s.isLocked.canPause && s.taxSettings.canPause != _updatedSettings.canPause) {
            s.taxSettings.canPause = _updatedSettings.canPause;
        }
        if(!s.isLocked.canBlacklist && s.taxSettings.canBlacklist != _updatedSettings.canBlacklist) {
            s.taxSettings.canBlacklist = _updatedSettings.canBlacklist;
        }
        if(!s.isLocked.maxBalanceAfterBuy && s.taxSettings.maxBalanceAfterBuy != _updatedSettings.maxBalanceAfterBuy) {
            s.taxSettings.maxBalanceAfterBuy = _updatedSettings.maxBalanceAfterBuy;
        }
        emit UpdatedSettings(s.taxSettings);
    }

    function updatePairAddress(address _newPairAddress) public onlyOwner {
        s.pairAddress = _newPairAddress;
        s.lpTokens[_newPairAddress] = true;
        emit AddedLPToken(_newPairAddress);
        emit UpdatedPairAddress(_newPairAddress);
    }

    function updateTaxHelperIndex(uint8 _newIndex) public onlyOwner {
        s.taxHelperIndex = _newIndex;
        emit UpdatedTaxHelperIndex(_newIndex);
    }

    function addTaxWhitelistedAddress(address _address) public onlyOwner {
        s.taxWhitelist[_address] = true;
        emit AddedTaxWhitelistAddress(_address);
    }

    function removeTaxWhitelistedAddress(address _address) public onlyOwner {
        s.taxWhitelist[_address] = false;
        emit RemovedTaxWhitelistAddress(_address);
    }

    function updateTaxWhitelistBatch(address[] calldata _updatedAddresses, bool _isTaxWhitelisted) public onlyOwner {
        for(uint i = 0; i < _updatedAddresses.length; i++) {
            s.taxWhitelist[_updatedAddresses[i]] = _isTaxWhitelisted;
            if(_isTaxWhitelisted) {
                emit AddedTaxWhitelistAddress(_updatedAddresses[i]);
            } else {
                emit RemovedTaxWhitelistAddress(_updatedAddresses[i]);
            }
        }
    }
}


// File contracts/libraries/FullMath.sol

// 


/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
   /// @notice Calculates floor(a├ùb├╖denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
/// @param a The multiplicand
/// @param b The multiplier
/// @param denominator The divisor
/// @return result The 256-bit result
/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
        require(denominator > 0);
        assembly {
            result := div(prod0, denominator)
        }
        return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
        remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    unchecked {
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
        }
    }

    /// @notice Calculates ceil(a├ùb├╖denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// File contracts/facets/Tax.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

// This contract logs all tokens on the platform


contract TaxFacet is Ownable {
    Storage internal s;

    event MarketInit(uint256 timestamp, uint256 blockNumber);
    event BuyBackTaxInitiated(address _sender, uint256 _fee, address _wallet, bool _isBuy);
    event TransactionTaxInitiated(address _sender, uint256 _fee, address _wallet, bool _isBuy);
    event LPTaxInitiated(address _sender, uint256 _fee, address _wallet, bool _isBuy);
    event CustomTaxInitiated(address _sender, uint256 _fee, address _wallet, bool _isBuy);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Reflect(uint256 tAmount, uint256 rAmount, uint256 rTotal_, uint256 teeTotal_);
    event ExcludedAccount(address account);
    event IncludedAccount(address account);

    function paused() internal view returns (bool) {
        return s.isPaused;
    }

    function isBlacklisted(address _address) internal view returns (bool) {
        return s.blacklist[_address];
    }

    /// @notice Handles the taxes for the token.
    /// Calls the appropriate tax helper contract to handle 
    /// LP and BuyBack tax logic
    /// @dev handles every tax within the tax facet. 
    /// @param sender the one sending the transaction
    /// @param recipient the one receiving the transaction
    /// @param amount the amount of tokens being sent
    /// @return totalTaxAmount the total amount of the token taxed
    function handleTaxes(address sender, address recipient, uint256 amount) public virtual returns (uint256 totalTaxAmount) {
        // restrict it to being only called by registered tokens
        require(IMintFactory(s.factory).tokenIsRegistered(address(this)));
        bool isBuy = false;

        if(s.lpTokens[sender]) {
            isBuy = true;
            if(!s.marketInit) {
                s.marketInit = true;
                s.antiBotSettings.startBlock = block.number;
                s.marketInitBlockTime = block.timestamp;
                emit MarketInit(block.timestamp, block.number);
            }
        }

        if(!s.lpTokens[sender] && !s.lpTokens[recipient]) {
            return 0;
        }

        if(isBuy && s.taxWhitelist[recipient]) {
            return 0;
        }

        if(!isBuy && s.taxWhitelist[sender]) {
            return 0;
        }

        ITaxHelper TaxHelper = ITaxHelper(IMintFactory(s.factory).getTaxHelperAddress(s.taxHelperIndex));
        if(sender == address(TaxHelper) || recipient == address(TaxHelper)) {
            return 0;
        }
        totalTaxAmount;
        uint256 fee;
        if(s.taxSettings.buyBackTax && !isBuy) {
            if(TaxHelper.lpTokenHasReserves(s.pairAddress)) {
                fee = amount * s.fees.buyBackTax / s.DENOMINATOR;
            }
            
            if(fee != 0) {
                _transfer(sender, address(TaxHelper), fee);

                TaxHelper.initiateBuyBackTax(address(this), address(s.buyBackWallet));
                emit BuyBackTaxInitiated(sender, fee, address(s.buyBackWallet), isBuy);
                totalTaxAmount += fee;
            }
            fee = 0;
        }
        if(s.taxSettings.transactionTax) {
            if(isBuy) {
                fee = amount * s.fees.transactionTax.buy / s.DENOMINATOR;
            } else {
                fee = amount * s.fees.transactionTax.sell / s.DENOMINATOR;
            }
            if(fee != 0) {
                _transfer(sender, s.transactionTaxWallet, fee);
                emit TransactionTaxInitiated(sender, fee, s.transactionTaxWallet, isBuy);
                totalTaxAmount += fee;
            }
            fee = 0;
        }
        if(s.taxSettings.lpTax && !isBuy) {
            if(TaxHelper.lpTokenHasReserves(s.pairAddress)) {
                fee = amount * s.fees.lpTax / s.DENOMINATOR;
            }
            if(fee != 0) {
                _transfer(sender, address(TaxHelper), fee);
                TaxHelper.initiateLPTokenTax(address(this), address(s.lpWallet));
                emit LPTaxInitiated(sender, fee, address(s.lpWallet), isBuy);
                totalTaxAmount += fee;
            }
            fee = 0;
        }
        if(s.customTaxes.length > 0) {
            for(uint8 i = 0; i < s.customTaxes.length; i++) {
                uint256 customFee;
                if(isBuy) {
                    customFee = amount * s.customTaxes[i].fee.buy / s.DENOMINATOR;
                } else {
                    customFee = amount * s.customTaxes[i].fee.sell / s.DENOMINATOR;
                }
                fee += customFee;
                if(fee != 0) {
                    totalTaxAmount += fee;
                    _transfer(sender, s.customTaxes[i].wallet, fee);
                    emit CustomTaxInitiated(sender, fee, s.customTaxes[i].wallet, isBuy);
                    fee = 0;
                }
            }
        }    
    }

    /// @notice internal transfer method
    /// @dev includes checks for all features not handled by handleTaxes()
    /// @param sender the one sending the transaction
    /// @param recipient the one receiving the transaction
    /// @param amount the amount of tokens being sent
    function _transfer(address sender, address recipient, uint256 amount) public {
        // restrict it to being only called by registered tokens
        if(!IMintFactory(s.factory).tokenGeneratorIsAllowed(msg.sender)) {
            require(IMintFactory(s.factory).tokenIsRegistered(address(this)));
        }
        require(sender != address(0), "ETFZ");
        require(recipient != address(0), "ETTZ");
        require(amount > 0, "TGZ");
        require(!paused(), "TP");
        require(!isBlacklisted(sender), "SB");
        require(!isBlacklisted(recipient), "RB"); 
        require(!isBlacklisted(tx.origin), "SB");
        // Reflection Transfers
        if(s.taxSettings.holderTax) {
            if (s._isExcluded[sender] && !s._isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
            } else if (!s._isExcluded[sender] && s._isExcluded[recipient]) {
                _transferToExcluded(sender, recipient, amount);
            } else if (!s._isExcluded[sender] && !s._isExcluded[recipient]) {
                _transferStandard(sender, recipient, amount);
            } else if (s._isExcluded[sender] && s._isExcluded[recipient]) {
                _transferBothExcluded(sender, recipient, amount);
            } else {
                _transferStandard(sender, recipient, amount);
            }
        } else {
            // Non Reflection Transfer
            _beforeTokenTransfer(sender, recipient, amount);

            uint256 senderBalance = s._tOwned[sender];
            require(senderBalance >= amount, "ETA");
            s._tOwned[sender] = senderBalance - amount;
            s._tOwned[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


    // Reflection Functions


    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!s._isExcluded[sender], "EA");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        s._rOwned[sender] = s._rOwned[sender] - rAmount;
        s._rTotal = s._rTotal - rAmount;
        s._tFeeTotal = s._tFeeTotal + tAmount;
        emit Reflect(tAmount, rAmount, s._rTotal, s._tFeeTotal);
        ITaxHelper TaxHelper = ITaxHelper(IMintFactory(s.factory).getTaxHelperAddress(s.taxHelperIndex));
        TaxHelper.sync(s.pairAddress);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= s._tTotal, "ALS");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256)  {
        require(rAmount <= s._rTotal, "ALR");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeAccount(address account) external onlyOwner {
        require(!s._isExcluded[account], "AE");
        if(s._rOwned[account] > 0) {
            s._tOwned[account] = tokenFromReflection(s._rOwned[account]);
        }
        s._isExcluded[account] = true;
        s._excluded.push(account);
        emit ExcludedAccount(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(s._isExcluded[account], "AI");
        for (uint256 i = 0; i < s._excluded.length; i++) {
            if (s._excluded[i] == account) {
                s._excluded[i] = s._excluded[s._excluded.length - 1];
                s._tOwned[account] = 0;
                s._isExcluded[account] = false;
                s._excluded.pop();
                break;
            }
        }
        emit IncludedAccount(account);
    }

    function isExcluded(address account) external view returns(bool) {
        return s._isExcluded[account];
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        s._rOwned[sender] = s._rOwned[sender] - rAmount;
        s._rOwned[recipient] = s._rOwned[recipient] + rTransferAmount;    
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        s._rOwned[sender] = s._rOwned[sender] - rAmount;
        s._tOwned[recipient] = s._tOwned[recipient] + tTransferAmount;
        s._rOwned[recipient] = s._rOwned[recipient] + rTransferAmount;           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        s._tOwned[sender] = s._tOwned[sender] - tAmount;
        s._rOwned[sender] = s._rOwned[sender] - rAmount;
        s._rOwned[recipient] = s._rOwned[recipient] + rTransferAmount;   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        s._tOwned[sender] = s._tOwned[sender] - tAmount;
        s._rOwned[sender] = s._rOwned[sender] - rAmount;
        s._tOwned[recipient] = s._tOwned[recipient] + tTransferAmount;
        s._rOwned[recipient] = s._rOwned[recipient] + rTransferAmount;        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        s._rTotal = s._rTotal - rFee;
        s._tFeeTotal = s._tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount / s.fees.holderTax;
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = s._rTotal;
        uint256 tSupply = s._tTotal;      
        for (uint256 i = 0; i < s._excluded.length; i++) {
            if (s._rOwned[s._excluded[i]] > rSupply || s._tOwned[s._excluded[i]] > tSupply) return (s._rTotal, s._tTotal);
            rSupply = rSupply - s._rOwned[s._excluded[i]];
            tSupply = tSupply - s._tOwned[s._excluded[i]];
        }
        if (rSupply < s._rTotal / s._tTotal) return (s._rTotal, s._tTotal);
        return (rSupply, tSupply);
    }

    function burn(uint256 amount) public {
        address taxHelper = IMintFactory(s.factory).getTaxHelperAddress(s.taxHelperIndex);
        require(msg.sender == taxHelper || msg.sender == owner(), "RA");
        _burn(owner(), amount);
    }

    /// @notice custom burn to handle reflection
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "EBZ");

        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeBurn(account, amount);
        } 

        _beforeTokenTransfer(account, address(0), amount);

        if(s.taxSettings.holderTax && !s._isExcluded[account]) {
            (uint256 rAmount,,,,) = _getValues(amount);
            s._rOwned[account] = s._rOwned[account] - rAmount;
            s._rTotal = s._rTotal - rAmount;
            s._tFeeTotal = s._tFeeTotal + amount;
        }

        uint256 accountBalance = s._tOwned[account];
        require(accountBalance >= amount, "EBB");
        s._tOwned[account] = accountBalance - amount;
        s._tTotal -= amount;

        emit Transfer(account, address(0), amount);
    }
    
}


// File contracts/facets/Wallets.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract WalletsFacet is Ownable {
    Storage internal s;

    event CreatedBuyBackWallet(address _wallet);
    event CreatedLPWallet(address _wallet);
    event UpdatedBuyBackWalletThreshold(uint256 _newThreshold);
    event UpdatedLPWalletThreshold(uint256 _newThreshold);

    function createBuyBackWallet(address _factory, address _token, uint256 _newThreshold) external returns (address) {
        BuyBackWallet newBuyBackWallet = new BuyBackWallet(_factory, _token,_newThreshold);
        emit CreatedBuyBackWallet(address(newBuyBackWallet));
        return address(newBuyBackWallet);
    }

    function createLPWallet(address _factory, address _token, uint256 _newThreshold) external returns (address) {
        LPWallet newLPWallet = new LPWallet(_factory, _token, _newThreshold);
        emit CreatedLPWallet(address(newLPWallet));
        return address(newLPWallet);
    }

    function updateBuyBackWalletThreshold(uint256 _newThreshold) public onlyOwner {
        IBuyBackWallet(s.buyBackWallet).updateThreshold(_newThreshold);
        emit UpdatedBuyBackWalletThreshold(_newThreshold);
    }

    function updateLPWalletThreshold(uint256 _newThreshold) public onlyOwner {
        ILPWallet(s.lpWallet).updateThreshold(_newThreshold);
        emit UpdatedLPWalletThreshold(_newThreshold);
    }

}


// File contracts/FeeHelper.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


contract FeeHelper is Ownable{
    
    struct Settings {
        uint256 GENERATOR_FEE;
        uint256 FEE; 
        uint256 DENOMINATOR;
        address payable FEE_ADDRESS;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.GENERATOR_FEE = 0;
        SETTINGS.FEE = 100;
        SETTINGS.DENOMINATOR = 10000;
        SETTINGS.FEE_ADDRESS = payable(msg.sender);
    }

    function getGeneratorFee() external view returns(uint256) {
        return SETTINGS.GENERATOR_FEE;
    }
    
    function getFee() external view returns(uint256) {
        return SETTINGS.FEE;
    }

    function getFeeDenominator() external view returns(uint256) {
        return SETTINGS.DENOMINATOR;
    }

    function setGeneratorFee(uint256 _fee) external onlyOwner {
        SETTINGS.GENERATOR_FEE = _fee;
    }
    
    function setFee(uint _fee) external onlyOwner {
        SETTINGS.FEE = _fee;
    }
    
    function getFeeAddress() external view returns(address) {
        return SETTINGS.FEE_ADDRESS;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner {
        SETTINGS.FEE_ADDRESS = _feeAddress;
    }
}


// File contracts/interfaces/IUniswapV2Router01.sol


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File contracts/interfaces/ICamelotV2Router.sol


interface ICamelotRouter is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;


}


// File contracts/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/libraries/ERC20.sol

// 

// File @openzeppelin/contracts/token/ERC20/[email protected]


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File contracts/libraries/Pausable.sol

// 
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}


// File contracts/libraries/EnumerableSet.sol

// 
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)



/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File contracts/MintFactory.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


// This contract logs all tokens on the platform


contract MintFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private tokens;
    EnumerableSet.AddressSet private tokenGenerators;

    struct TaxHelper {
        string Name;
        address Address;
        uint256 Index;
    }

    mapping(uint => TaxHelper) private taxHelpersData;
    address[] private taxHelpers;
     
    mapping(address => address[]) private tokenOwners;

    address private FacetHelper;
    address private FeeHelper;
    address private LosslessController;

    event TokenRegistered(address tokenOwner, address tokenContract);
    event AllowTokenGenerator(address _address, bool _allow);

    event AddedTaxHelper(string _name, address _address, uint256 _index);
    event UpdatedTaxHelper(address _newAddress, uint256 _index);

    event UpdatedFacetHelper(address _newAddress);
    event UpdatedFeeHelper(address _newAddress);
    event UpdatedLosslessController(address _newAddress);
    
    function adminAllowTokenGenerator (address _address, bool _allow) public onlyOwner {
        if (_allow) {
            tokenGenerators.add(_address);
        } else {
            tokenGenerators.remove(_address);
        }
        emit AllowTokenGenerator(_address, _allow);
    }

    function addTaxHelper(string calldata _name, address _address) public onlyOwner {
        uint256 index = taxHelpers.length;
        TaxHelper memory newTaxHelper;
        newTaxHelper.Name = _name;
        newTaxHelper.Address = _address;
        newTaxHelper.Index = index;
        taxHelpersData[index] = newTaxHelper;
        taxHelpers.push(_address);
        emit AddedTaxHelper(_name, _address, index);
    }

    function updateTaxHelper(uint256 _index, address _address) public onlyOwner {
        taxHelpersData[_index].Address = _address;
        taxHelpers[_index] = _address;
        emit UpdatedTaxHelper(_address, _index);
    }

    function getTaxHelperAddress(uint256 _index) public view returns(address){
        return taxHelpers[_index];
    }

    function getTaxHelpersDataByIndex(uint256 _index) public view returns(TaxHelper memory) {
        return taxHelpersData[_index];
    }
    
    /**
     * @notice called by a registered tokenGenerator upon token creation
     */
    function registerToken (address _tokenOwner, address _tokenAddress) public {
        require(tokenGenerators.contains(msg.sender), 'FORBIDDEN');
        tokens.add(_tokenAddress);
        tokenOwners[_tokenOwner].push(_tokenAddress);
        emit TokenRegistered(_tokenOwner, _tokenAddress);
    }

     /**
     * @notice gets a token at index registered under a user address
     * @return token addresses registered to the user address
     */
     function getTokenByOwnerAtIndex(address _tokenOwner, uint256 _index) external view returns(address) {
         return tokenOwners[_tokenOwner][_index];
     }
     
     /**
     * @notice gets the total of tokens registered under a user address
     * @return uint total of token addresses registered to the user address
     */
     
     function getTokensLengthByOwner(address _tokenOwner) external view returns(uint256) {
         return tokenOwners[_tokenOwner].length;
     }
    
    /**
     * @notice Number of allowed tokenGenerators
     */
    function tokenGeneratorsLength() external view returns (uint256) {
        return tokenGenerators.length();
    }
    
    /**
     * @notice Gets the address of a registered tokenGenerator at specified index
     */
    function tokenGeneratorAtIndex(uint256 _index) external view returns (address) {
        return tokenGenerators.at(_index);
    }

    /**
     * @notice returns true if user is allowed to generate tokens
     */
    function tokenGeneratorIsAllowed(address _tokenGenerator) external view returns (bool) {
        return tokenGenerators.contains(_tokenGenerator);
    }
    
    /**
     * @notice returns true if the token address was generated by the Unicrypt token platform
     */
    function tokenIsRegistered(address _tokenAddress) external view returns (bool) {
        return tokens.contains(_tokenAddress);
    }
    
    /**
     * @notice The length of all tokens on the platform
     */
    function tokensLength() external view returns (uint256) {
        return tokens.length();
    }
    
    /**
     * @notice gets a token at a specific index. Although using Enumerable Set, since tokens are only added and not removed, indexes will never change
     * @return the address of the token contract at index
     */
    function tokenAtIndex(uint256 _index) external view returns (address) {
        return tokens.at(_index);
    }

    // Helpers and Controllers
    
    function getFacetHelper() public view returns (address) {
        return FacetHelper;
    }

    function updateFacetHelper(address _newFacetHelperAddress) public onlyOwner {
        require(_newFacetHelperAddress != address(0));
        FacetHelper = _newFacetHelperAddress;
        emit UpdatedFacetHelper(_newFacetHelperAddress);
    }

    function getFeeHelper() public view returns (address) {
        return FeeHelper;
    }

    function updateFeeHelper(address _newFeeHelperAddress) public onlyOwner {
        require(_newFeeHelperAddress != address(0));
        FeeHelper = _newFeeHelperAddress;
        emit UpdatedFeeHelper(_newFeeHelperAddress);
    }

    function getLosslessController() public view returns (address) {
        return LosslessController;
    }

    function updateLosslessController(address _newLosslessControllerAddress) public onlyOwner {
        require(_newLosslessControllerAddress != address(0));
        LosslessController = _newLosslessControllerAddress;
        emit UpdatedLosslessController(_newLosslessControllerAddress);
    }
}


// File contracts/TaxToken.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



contract TaxToken is Ownable{
    Storage internal s;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    struct ConstructorParams {
        string name_; 
        string symbol_; 
        uint8 decimals_; 
        address creator_;
        uint256 tTotal_;
        uint256 _maxTax;
        TaxSettings _settings;
        TaxSettings _lockedSettings;
        Fees _fees;
        address _transactionTaxWallet;
        CustomTax[] _customTaxes;
        uint256 lpWalletThreshold;
        uint256 buyBackWalletThreshold;
        uint256 _taxHelperIndex;
        address admin_;
        address recoveryAdmin_;
        bool isLossless_;
        AntiBotSettings _antiBotSettings;
        uint256 _maxBalanceAfterBuy;
        SwapWhitelistingSettings _swapWhitelistingSettings;
    }

    constructor(
        ConstructorParams memory params,
        address _factory
        ) {
        address constructorFacetAddress = IFacetHelper(IMintFactory(_factory).getFacetHelper()).getConstructorFacet();
        (bool success, bytes memory result) = constructorFacetAddress.delegatecall(abi.encodeWithSignature("constructorHandler((string,string,uint8,address,uint256,uint256,(bool,bool,bool,bool,bool,bool,bool,bool),(bool,bool,bool,bool,bool,bool,bool,bool),((uint256,uint256),uint256,uint256,uint256),address,(string,(uint256,uint256),address,bool)[],uint256,uint256,uint256,address,address,bool,(uint256,uint256,uint256,uint256,bool),uint256,(uint256,bool)),address)", params, _factory));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
        IFeeHelper feeHelper = IFeeHelper(IMintFactory(s.factory).getFeeHelper());
        uint256 fee = FullMath.mulDiv(params.tTotal_, feeHelper.getFee(), feeHelper.getFeeDenominator());
        address feeAddress = feeHelper.getFeeAddress();
        _approve(params.creator_, msg.sender, fee);
        s.isTaxed = true;
        transferFrom(params.creator_, feeAddress, fee);
    }

    /// @notice this is the power behind Lossless
    function transferOutBlacklistedFunds(address[] calldata from) external {
        require(s.isLosslessOn); // added by us for extra protection
        require(_msgSender() == address(IMintFactory(s.factory).getLosslessController()), "LOL");
        for (uint i = 0; i < from.length; i++) {
            _transfer(from[i], address(IMintFactory(s.factory).getLosslessController()), balanceOf(from[i]));
        }
    }

    /// @notice Checks whether an address is blacklisted
    /// @param _address the address to check
    /// @return bool is blacklisted or not
    function isBlacklisted(address _address) public view returns (bool) {
        return s.blacklist[_address];
    }

    /// @notice Checks whether the contract has paused transactions
    /// @return bool is paused or not
    function paused() public view returns (bool) {
        if(s.taxSettings.canPause == false) {
            return false;
        }
        return s.isPaused;
    }

    /// @notice Handles the burning of token during the buyback tax process
    /// @dev must first receive the amount to be burned from the taxHelper contract (see initial transfer in function)
    /// @param _amount the amount to burn
    function buyBackBurn(uint256 _amount) external {
        address taxHelper = IMintFactory(s.factory).getTaxHelperAddress(s.taxHelperIndex);
        require(msg.sender == taxHelper, "RA");
        _transfer(taxHelper, owner(), _amount);

        address taxFacetAddress = IFacetHelper(IMintFactory(s.factory).getFacetHelper()).getTaxFacet();
        (bool success, bytes memory result) = taxFacetAddress.delegatecall(abi.encodeWithSignature("burn(uint256)", _amount));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
    }

    /// @notice Handles the taxes for the token.
    /// @dev handles every tax within the tax facet. 
    /// @param sender the one sending the transaction
    /// @param recipient the one receiving the transaction
    /// @param amount the amount of tokens being sent
    /// @return totalTaxAmount the total amount of the token taxed
    function handleTaxes(address sender, address recipient, uint256 amount) internal virtual returns (uint256 totalTaxAmount) {
        address taxFacetAddress = IFacetHelper(IMintFactory(s.factory).getFacetHelper()).getTaxFacet();
        (bool success, bytes memory result) = taxFacetAddress.delegatecall(abi.encodeWithSignature("handleTaxes(address,address,uint256)", sender, recipient, amount));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
        return abi.decode(result, (uint256));

    }

    // Getters

    function name() public view returns (string memory) {
        return s._name;
    }

    function symbol() public view returns (string memory) {
        return s._symbol;
    }

    function decimals() public view returns (uint8) {
        return s._decimals;
    }

    function totalSupply() public view returns (uint256) {
        return s._tTotal;
    }

    function CONTRACT_VERSION() public view returns (uint256) {
        return s.CONTRACT_VERSION;
    }

    function taxSettings() public view returns (TaxSettings memory) {
        return s.taxSettings;
    }
    
    function isLocked() public view returns (TaxSettings memory) {
        return s.isLocked;
    }

    function fees() public view returns (Fees memory) {
        return s.fees;
    }

    function customTaxes(uint _index) public view returns (CustomTax memory) {
        return s.customTaxes[_index];
    }

    function transactionTaxWallet() public view returns (address) {
        return s.transactionTaxWallet;
    }

    function customTaxLength() public view returns (uint256) {
        return s.customTaxLength;
    }

    function MaxTax() public view returns (uint256) {
        return s.MaxTax;
    }

    function MaxCustom() public view returns (uint8) {
        return s.MaxCustom;
    }

    function _allowances(address _address1, address _address2) public view returns (uint256) {
        return s._allowances[_address1][_address2];
    }

    function _isExcluded(address _address) public view returns (bool) {
        return s._isExcluded[_address];
    }

    function _tFeeTotal() public view returns (uint256) {
        return s._tFeeTotal;
    }

    function lpTokens(address _address) public view returns (bool) {
        return s.lpTokens[_address];
    }

    function factory() public view returns (address) {
        return s.factory;
    }

    function buyBackWallet() public view returns (address) {
        return s.buyBackWallet;
    }

    function lpWallet() public view returns (address) {
        return s.lpWallet;
    }

    function pairAddress() public view returns (address) {
        return s.pairAddress;
    }
    
    function taxHelperIndex() public view returns (uint256) {
        return s.taxHelperIndex;
    }

    function marketInit() public view returns (bool) {
        return s.marketInit;
    }

    function marketInitBlockTime() public view returns (uint256) {
        return s.marketInitBlockTime;
    }

    function antiBotSettings() public view returns (AntiBotSettings memory) {
        return s.antiBotSettings;
    }

    function maxBalanceAfterBuy() public view returns (uint256) {
        return s.maxBalanceAfterBuy;
    }

    function swapWhitelistingSettings() public view returns (SwapWhitelistingSettings memory) {
        return s.swapWhitelistingSettings;
    }

    function recoveryAdmin() public view returns (address) {
        return s.recoveryAdmin;
    }

    function admin() public view returns (address) {
        return s.admin;
    }

    function timelockPeriod() public view returns (uint256) {
        return s.timelockPeriod;
    }

    function losslessTurnOffTimestamp() public view returns (uint256) {
        return s.losslessTurnOffTimestamp;
    }

    function isLosslessTurnOffProposed() public view returns (bool) {
        return s.isLosslessTurnOffProposed;
    }

    function isLosslessOn() public view returns (bool) {
        return s.isLosslessOn;
    }

    function lossless() public view returns (ILosslessController) {
        return ILosslessController(IMintFactory(s.factory).getLosslessController());
    }


    // ERC20 Functions

    /// @dev modified to handle if the token has reflection active in it settings
    function balanceOf(address account) public view returns (uint256) {
        if(s.taxSettings.holderTax) {
            if (s._isExcluded[account]) return s._tOwned[account];
            return tokenFromReflection(s._rOwned[account]); 
        }
        return s._tOwned[account];
    }

    // Reflection Functions 
    // necessary to get reflection balance

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= s._rTotal, "ALR");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _getRate() public view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() public view returns(uint256, uint256) {
        uint256 rSupply = s._rTotal;
        uint256 tSupply = s._tTotal;      
        for (uint256 i = 0; i < s._excluded.length; i++) {
            if (s._rOwned[s._excluded[i]] > rSupply || s._tOwned[s._excluded[i]] > tSupply) return (s._rTotal, s._tTotal);
            rSupply = rSupply - s._rOwned[s._excluded[i]];
            tSupply = tSupply - s._tOwned[s._excluded[i]];
        }
        if (rSupply < s._rTotal / s._tTotal) return (s._rTotal, s._tTotal);
        return (rSupply, tSupply);
    }


    // ERC20 Functions continued 
    /// @dev modified slightly to add taxes

    function transfer(address recipient, uint256 amount) public returns (bool) {
        if(!s.isTaxed) {
            s.isTaxed = true;
            uint256 totalTaxAmount = handleTaxes(_msgSender(), recipient, amount);
            amount -= totalTaxAmount;
        }
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeTransfer(_msgSender(), recipient, amount);
        } 
        _transfer(_msgSender(), recipient, amount);
        s.isTaxed = false;
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).afterTransfer(_msgSender(), recipient, amount);
        } 
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return s._allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        if(!s.isTaxed) {
            s.isTaxed = true;
            uint256 totalTaxAmount = handleTaxes(sender, recipient, amount);
            amount -= totalTaxAmount;
        }
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeTransferFrom(_msgSender(), sender, recipient, amount);
        }
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = s._allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ETA");

        _approve(sender, _msgSender(), s._allowances[sender][_msgSender()] - amount);

        s.isTaxed = false;
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).afterTransfer(_msgSender(), recipient, amount);
        } 
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeIncreaseAllowance(_msgSender(), spender, addedValue);
        }
        _approve(_msgSender(), spender, s._allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
         if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
        }
        uint256 currentAllowance = s._allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "EABZ");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "EAFZ");
        require(spender != address(0), "EATZ");
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeApprove(_owner, spender, amount);
        } 

        s._allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        // AntiBot Checks
        address antiBotFacetAddress = IFacetHelper(IMintFactory(s.factory).getFacetHelper()).getAntiBotFacet();
        if(s.marketInit && s.antiBotSettings.isActive && s.lpTokens[sender]) {
            (bool success, bytes memory result) = antiBotFacetAddress.delegatecall(abi.encodeWithSignature("antiBotCheck(uint256,address)", amount, recipient));
            if (!success) {
                if (result.length < 68) revert();
                revert(abi.decode(result, (string)));
            }
        } 
        if(s.taxSettings.maxBalanceAfterBuy && s.lpTokens[sender]) {
            (bool success2, bytes memory result2) = antiBotFacetAddress.delegatecall(abi.encodeWithSignature("maxBalanceAfterBuyCheck(uint256,address)", amount, recipient));
            if (!success2) {
                if (result2.length < 68) revert();
                revert(abi.decode(result2, (string)));
            }
        } 
        if(s.marketInit && s.swapWhitelistingSettings.isActive && s.lpTokens[sender]) {
            (bool success3, bytes memory result3) = antiBotFacetAddress.delegatecall(abi.encodeWithSignature("swapWhitelistingCheck(address)", recipient));
            if (!success3) {
                if (result3.length < 68) revert();
                revert(abi.decode(result3, (string)));
            }
        } 
        address taxFacetAddress = IFacetHelper(IMintFactory(s.factory).getFacetHelper()).getTaxFacet();
        (bool success4, bytes memory result4) = taxFacetAddress.delegatecall(abi.encodeWithSignature("_transfer(address,address,uint256)", sender, recipient, amount));
        if (!success4) {
            if (result4.length < 68) revert();
            revert(abi.decode(result4, (string)));
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    /// @notice custom mint to handle fees
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "EMZ");
        require(s.taxSettings.canMint, "NM");
        require(!s.taxSettings.holderTax, "NM");
        if (s.isLosslessOn) {
            ILosslessController(IMintFactory(s.factory).getLosslessController()).beforeMint(account, amount);
        } 

        IFeeHelper feeHelper = IFeeHelper(IMintFactory(s.factory).getFeeHelper());
        uint256 fee = FullMath.mulDiv(amount, feeHelper.getFee(), feeHelper.getFeeDenominator());
        address feeAddress = feeHelper.getFeeAddress();

        _beforeTokenTransfer(address(0), account, amount);
        s._tTotal += amount;
        s._tOwned[feeAddress] += fee;
        s._tOwned[account] += amount - fee;

        emit Transfer(address(0), feeAddress, fee);
        emit Transfer(address(0), account, amount - fee);
    }

    function burn(uint256 amount) public {
        address taxFacetAddress = IFacetHelper(IMintFactory(s.factory).getFacetHelper()).getTaxFacet();
        (bool success, bytes memory result) = taxFacetAddress.delegatecall(abi.encodeWithSignature("burn(uint256)", amount));
        if (!success) {
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
    }

    /// @notice Handles all facet logic
    /// @dev Implements a customized version of the EIP-2535 Diamond Standard to add extra functionality to the contract
    /// https://github.com/mudgen/diamond-3 
    fallback() external {
        address facetHelper = IMintFactory(s.factory).getFacetHelper(); 
        address facet = IFacetHelper(facetHelper).facetAddress(msg.sig);
        require(facet != address(0), "Function does not exist");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
    
            let result := delegatecall(
                gas(),
                facet,
                ptr,
                calldatasize(),
                0,
                0
            )

            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
  
}


// File contracts/MintGenerator.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.


// This contract generates Token01 contracts and registers them in the TokenFactory.
// Ideally you should not interact with this contract directly, and use the Unicrypt token app instead so warnings can be shown where necessary.


contract MintGenerator is Ownable {
    
    uint256 public CONTRACT_VERSION = 1;


    IMintFactory public MINT_FACTORY;
    IFeeHelper public FEE_HELPER;
    
    constructor(address _mintFactory, address _feeHelper) {
        MINT_FACTORY = IMintFactory(_mintFactory);
        FEE_HELPER = IFeeHelper(_feeHelper);
    }
    
    /**
     * @notice Creates a new Token contract and registers it in the TokenFactory.sol.
     */
    
    function createToken (
      TaxToken.ConstructorParams calldata params
      ) public payable returns (address){
        require(msg.value == FEE_HELPER.getGeneratorFee(), 'FEE NOT MET');
        payable(FEE_HELPER.getFeeAddress()).transfer(FEE_HELPER.getGeneratorFee());
        TaxToken newToken = new TaxToken(params, address(MINT_FACTORY));
        MINT_FACTORY.registerToken(msg.sender, address(newToken));
        return address(newToken);
    }
}


// File contracts/interfaces/IUniswapV2Factory.sol


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/interfaces/IUniswapV2Pair.sol


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/TaxHelperCamelotV2.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



// add events

contract TaxHelperCamelotV2 is Ownable{
    
    ICamelotRouter router;
    IUniswapV2Factory factory;
    IMintFactory mintFactory;

    // event Buy
    event CreatedLPToken(address token0, address token1, address LPToken);

    constructor(address swapV2Router, address swapV2Factory, address _mintFactory) {
    router = ICamelotRouter(swapV2Router);
    factory = IUniswapV2Factory(swapV2Factory);
    mintFactory = IMintFactory(_mintFactory);
 
    }

    modifier isToken() {
        require(mintFactory.tokenIsRegistered(msg.sender), "RA");
        _;
    }

    function initiateBuyBackTax(address _token, address _wallet) payable external isToken returns(bool) {
        ITaxToken token = ITaxToken(_token);
        uint256 _amount = token.balanceOf(address(this));
        address[] memory addressPaths = new address[](2);
        addressPaths[0] = _token;
        addressPaths[1] = router.WETH();
        token.approve(address(router), _amount);
        if(_amount > 0) {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, addressPaths, _wallet, address(0), block.timestamp);
        }
        IBuyBackWallet buyBackWallet = IBuyBackWallet(_wallet);
        bool res = buyBackWallet.checkBuyBackTrigger();
        if(res) {
            addressPaths[0] = router.WETH();
            addressPaths[1] = _token;
            uint256 amountEth = buyBackWallet.sendEthToTaxHelper();
            uint256 balanceBefore = token.balanceOf(address(this));
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountEth}(0, addressPaths, address(this), address(0), block.timestamp);
            // burn baby burn!
            uint256 balanceAfter = token.balanceOf(address(this));
            uint256 amountToBurn = balanceAfter - balanceBefore;
            token.approve(token.owner(), amountToBurn);
            token.buyBackBurn(amountToBurn);
        }
        return true;
    }

    function initiateLPTokenTax(address _token, address _wallet) external isToken returns (bool) {
        ITaxToken token = ITaxToken(_token);
        uint256 _amount = token.balanceOf(address(this));
        address[] memory addressPaths = new address[](2);
        addressPaths[0] = _token;
        addressPaths[1] = router.WETH();
        uint256 halfAmount = _amount / 2;
        uint256 otherHalf = _amount - halfAmount;
        token.transfer(_wallet, otherHalf);
        token.approve(address(router), halfAmount);
        if(halfAmount > 0) {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(halfAmount, 0, addressPaths, _wallet, address(0), block.timestamp);
        }
        ILPWallet lpWallet = ILPWallet(_wallet);
        bool res = lpWallet.checkLPTrigger();
        if(res) {
            lpWallet.transferBalanceToTaxHelper();
            uint256 amountEth = lpWallet.sendEthToTaxHelper();
            uint256 tokenBalance = token.balanceOf(address(this));
            token.approve(address(router), tokenBalance);
            router.addLiquidityETH{value: amountEth}(_token, tokenBalance, 0, 0, token.owner(), block.timestamp + 20 minutes);
            uint256 ethDust = address(this).balance;
            if(ethDust > 0) {
                (bool sent,) = _wallet.call{value: ethDust}("");
                require(sent, "Failed to send Ether");
            }
            uint256 tokenDust = token.balanceOf(address(this));
            if(tokenDust > 0) {
                token.transfer(_wallet, tokenDust);
            }
        }
        return true;
    }    
    
    function createLPToken() external returns(address lpToken) {
        // lpToken = factory.createPair(msg.sender, router.WETH());
        // emit CreatedLPToken(msg.sender, router.WETH(), lpToken);
        // Camelot V2 fails upon LP creation during the constructor
        // return zaero address to be updated after creation.
        return address(0);
    }

    function lpTokenHasReserves(address _lpToken) public view returns (bool) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(_lpToken).getReserves();
        return reserve0 > 0 && reserve1 > 0;
    }

    function sync(address _lpToken) public {
        IUniswapV2Pair(_lpToken).sync();
    }

    receive() payable external {
    }

}


// File contracts/TaxHelperUniswapV2.sol

// 
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.



// add events

contract TaxHelperUniswapV2 is Ownable{
    
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;
    IMintFactory mintFactory;

    // event Buy
    event CreatedLPToken(address token0, address token1, address LPToken);

    constructor(address swapV2Router, address swapV2Factory, address _mintFactory) {
    router = IUniswapV2Router02(swapV2Router);
    factory = IUniswapV2Factory(swapV2Factory);
    mintFactory = IMintFactory(_mintFactory);
 
    }

    modifier isToken() {
        require(mintFactory.tokenIsRegistered(msg.sender), "RA");
        _;
    }

    function initiateBuyBackTax(address _token, address _wallet) payable external isToken returns(bool) {
        ITaxToken token = ITaxToken(_token);
        uint256 _amount = token.balanceOf(address(this));
        address[] memory addressPaths = new address[](2);
        addressPaths[0] = _token;
        addressPaths[1] = router.WETH();
        token.approve(address(router), _amount);
        if(_amount > 0) {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, addressPaths, _wallet, block.timestamp);
        }
        IBuyBackWallet buyBackWallet = IBuyBackWallet(_wallet);
        bool res = buyBackWallet.checkBuyBackTrigger();
        if(res) {
            addressPaths[0] = router.WETH();
            addressPaths[1] = _token;
            uint256 amountEth = buyBackWallet.sendEthToTaxHelper();
            uint256 balanceBefore = token.balanceOf(address(this));
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountEth}(0, addressPaths, address(this), block.timestamp);
            // burn baby burn!
            uint256 balanceAfter = token.balanceOf(address(this));
            uint256 amountToBurn = balanceAfter - balanceBefore;
            token.approve(token.owner(), amountToBurn);
            token.buyBackBurn(amountToBurn);
        }
        return true;
    }

    function initiateLPTokenTax(address _token, address _wallet) external isToken returns (bool) {
        ITaxToken token = ITaxToken(_token);
        uint256 _amount = token.balanceOf(address(this));
        address[] memory addressPaths = new address[](2);
        addressPaths[0] = _token;
        addressPaths[1] = router.WETH();
        uint256 halfAmount = _amount / 2;
        uint256 otherHalf = _amount - halfAmount;
        token.transfer(_wallet, otherHalf);
        token.approve(address(router), halfAmount);
        if(halfAmount > 0) {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(halfAmount, 0, addressPaths, _wallet, block.timestamp);
        }
        ILPWallet lpWallet = ILPWallet(_wallet);
        bool res = lpWallet.checkLPTrigger();
        if(res) {
            lpWallet.transferBalanceToTaxHelper();
            uint256 amountEth = lpWallet.sendEthToTaxHelper();
            uint256 tokenBalance = token.balanceOf(address(this));
            token.approve(address(router), tokenBalance);
            router.addLiquidityETH{value: amountEth}(_token, tokenBalance, 0, 0, token.owner(), block.timestamp + 20 minutes);
            uint256 ethDust = address(this).balance;
            if(ethDust > 0) {
                (bool sent,) = _wallet.call{value: ethDust}("");
                require(sent, "Failed to send Ether");
            }
            uint256 tokenDust = token.balanceOf(address(this));
            if(tokenDust > 0) {
                token.transfer(_wallet, tokenDust);
            }
        }
        return true;
    }    
    
    function createLPToken() external returns(address lpToken) {
        lpToken = factory.createPair(msg.sender, router.WETH());
        emit CreatedLPToken(msg.sender, router.WETH(), lpToken);
    }

    function lpTokenHasReserves(address _lpToken) public view returns (bool) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(_lpToken).getReserves();
        return reserve0 > 0 && reserve1 > 0;
    }

    function sync(address _lpToken) public {
        IUniswapV2Pair(_lpToken).sync();
    }

    receive() payable external {
    }

}