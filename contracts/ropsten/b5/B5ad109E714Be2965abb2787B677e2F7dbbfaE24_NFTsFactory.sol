// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";
import "./Security/PausableUpgradeable.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Access/OwnableUpgradeable.sol";
import "./Interfaces/INFTsFactory.sol";
import "./Proxies/ERC1967Proxy.sol";
import "./NFTs.sol";

contract NFTsFactory is Initializable, INFTsFactory, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  

  //Implementation address
  address NFTsAddress;
  
  //Iterable proxy mapping
  mapping(address=> address) internal assetsMap;
  address[] internal assets;


  function __NFTsFactory_init() public virtual override initializer {
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();

    NFTsAddress = address(new NFTs());
  }


  function deployTokens(
    string memory uri_,
    address assetWallet,
    address hoa,
    address treasury, 
    string memory _contractName, 
    uint256 propTaxId
  ) public virtual whenNotPaused returns(address){
      ERC1967Proxy proxy = new ERC1967Proxy(NFTsAddress, abi.encodeWithSelector(NFTs(address(0)).initialize.selector, uri_, assetWallet, hoa, treasury, _contractName, propTaxId));
      _transferOwnership(hoa);

      address assetAddress = address(proxy);
      assetsMap[assetWallet] = assetAddress;
      assets.push(assetAddress);

      emit proxyDeployed(assetAddress);

      return (assetAddress);
  }


  function pause() external onlyOwner {
    _pause();
  }


  function unpause() external onlyOwner {
    _unpause();
  }

  function isPaused() public view override returns(bool){
    return _paused;
  }

  function assetContractAddress(address assetWallet) public view virtual override returns(address) {
    return assetsMap[assetWallet];
  }

  function numOfAssets() public view virtual override returns(uint256) {
    return uint256(assets.length);
  }

  function allAssets() public view virtual override returns(address[] memory) {
    return assets;
  }

  function _authorizeUpgrade(address newFactory) internal virtual override onlyOwner {
    require(AddressUpgradeable.isContract(newFactory), "NFTsFactory: new factory must be a contract");
    require(newFactory != address(0), "NFTsFactory: set to the zero address");
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Interfaces/IERC1155Upgradeable.sol";
import "./Interfaces/IERC1155MetadataURIUpgradeable.sol";
import "./Tokens/ERC1155HolderUpgradeable.sol";
import "./Utils/ERC165Upgradeable.sol";
import "./Utils/ContextUpgradeable.sol";
import "./Utils/AddressUpgradeable.sol";
import "./Utils/StringsUpgradeable.sol";
import "./Access/AccessControlUpgradeable.sol";
import "./Proxies/Initializable.sol";
import "./Proxies/UUPSUpgradeable.sol";


contract NFTs is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable, ERC1155HolderUpgradeable , AccessControlUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;


  address assetWallet; //UI:1.Owner Details
  string private contractName;
  uint256 private taxId;
  string private _uri;
  // Array of only 6 tokens that are available to mint
  uint256[5] private availableTokens;
  // from token id to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;
  // token owner authorize operator's transaction
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  // Total supply of each id
  mapping(uint256 => uint256) private _totalSupply;
  // To prevent duplicate properties
  mapping(uint256 => bool) private propertyExists;

  mapping(address => Property) public propertyDetails;
  mapping(uint256 => address) public erc20Tansfers; 


  struct TokensIssued{
    uint256 TokenId;
    uint256 TimeStamp;
  }

  struct Property{
    string[] ImagesHash;  //UI:6. property Images
    string[] Address;  //UI:3. physical Address
    string[] SchoolsDist;  //UI:4. Neighborhood
    string[] Documents; //UI:7. property Documents
    uint256 Tax; //UI:5. T.I.M.E contract details
    uint256 Insurance;
    uint256 Maintenance;
    uint256 Expenses;
    string[] Floors; //UI:8. 
    string[] Amenities;  //UI:9.
    string[] PropertyInfo;  //UI:2. Property Info.
    TokensIssued[] tokens;
  }

  uint256 public constant TITLE = 0;
  uint256 public constant MANAGEMENT_RIGHT = 1;
  uint256 public constant INCOME_RIGHT = 2;
  uint256 public constant EQUITY_RIGHT = 3;
  uint256 public constant OCCUPANCY_RIGHT = 4;
  uint256 public constant GOVERNANCE_RIGHT = 5;


  bytes32 public constant TREASURY_ROLE = keccak256(abi.encodePacked("TREASURY_ROLE"));
  

  function initialize(string memory uri_, address _assetWallet, address hoa, address treasury, string memory _contractName, uint256 propTaxId) public initializer {
    __ERC1155Holder_init();
    __UUPSUpgradeable_init();
    __AccessControl_init();
  
    contractName = _contractName;
    assetWallet = _assetWallet;
    taxId = propTaxId;

    _setURI(uri_);
    
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, hoa);
    _setupRole(TREASURY_ROLE, treasury);
  
    propertyExists[taxId] = true;
  }


  function modifyUri(uint256 id) public view virtual onlyRole(DEFAULT_ADMIN_ROLE) returns(string memory) {
    require(exists(id),"NFT: non existent token");

    return string(abi.encodePacked(_uri, id.toString()));
  }

  function totalSupply(uint256 id) public view override returns (uint256) {
    return _totalSupply[id];
  }

  function exists(uint256 id) public view override returns (bool) {
    return NFTs.totalSupply(id) > 0;
  }

  function uri(uint256) public view override returns (string memory) {
    return _uri;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable, ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool) {
    return 
    interfaceId == type(IERC1155Upgradeable).interfaceId ||
    interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
    interfaceId == type(AccessControlUpgradeable).interfaceId ||

    super.supportsInterface(interfaceId);
  }

  function balanceOf(address account, uint256 id) public view override returns (uint256) {
    require(account != address(0), "NFT: balance query for the zero address");
    return _balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view override returns (uint256[] memory) {
    require(accounts.length == ids.length, "NFT: accounts and ids length mismatch");
    
    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function isApprovedForAll(address account, address operator) public view override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  function assetDetails(
    string[] memory imageshash,
    string[] memory assetAddress,
    string[] memory neighborhood,
    string[] memory docs,
    uint256 tax,
    uint256 insurance,
    uint256 maintenance,
    uint256 expenses,
    string[] memory floors,
    string[] memory amenities,
    string[] memory info
  ) public virtual override {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NFT: unauthorized personnel");
   
    propertyDetails[assetWallet].ImagesHash = imageshash;
    propertyDetails[assetWallet].Address = assetAddress;
    propertyDetails[assetWallet].SchoolsDist = neighborhood;
    propertyDetails[assetWallet].Documents = docs;
    propertyDetails[assetWallet].Tax = tax;
    propertyDetails[assetWallet].Insurance = insurance;
    propertyDetails[assetWallet].Maintenance = maintenance;
    propertyDetails[assetWallet].Expenses = expenses;
    propertyDetails[assetWallet].Floors = floors;
    propertyDetails[assetWallet].Amenities = amenities;
    propertyDetails[assetWallet].PropertyInfo = info;

    emit AssetAdded (assetWallet, imageshash, docs);

  }

  function transferToVault(uint256 id, address vaultContract) public virtual override onlyRole(TREASURY_ROLE) returns(uint256, address){
    require(balanceOf(address(this), id) <= 1, 'NFT: balance is not enough');
    require(AddressUpgradeable.isContract(vaultContract), "NFT: transfer to vault contract only");

    erc20Tansfers[id] = vaultContract;

    _safeTransferFrom(address(this), vaultContract, id, 1, "");

    emit TransferToVault(id, vaultContract);

    return (id, vaultContract);
  }


  function mintNft(uint256 id) public virtual override onlyRole(TREASURY_ROLE) returns(uint256){
    require(!exists(id) && id <= availableTokens.length,"NFT: token already minted or out of range");
    
    _mint(address(this), id, 1, "");

    propertyDetails[assetWallet].tokens.push(TokensIssued({TokenId: id, TimeStamp: block.timestamp}));

    return id;
  }

  function mintBatchNfts(uint256[] memory ids, uint256[] memory amounts) public virtual override onlyRole(TREASURY_ROLE) returns(uint256[] memory) {
  
    uint256 i = 0;
    for (i = 0; i <= ids.length; i++) {

      propertyDetails[assetWallet].tokens.push(TokensIssued({TokenId: ids[i], TimeStamp: block.timestamp}));

    }

    require(!exists(ids[i]) && ids[i] <= availableTokens.length, "NFT: token is minted or out of range");

    _mintBatch(address(this),ids, amounts ,"");

     return ids;
  }

  function burnNFT(uint256 id) public virtual override onlyRole(TREASURY_ROLE) {
    require(exists(id), "NFT: NFT does not exist");

    _burn(address(this), id, 1);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
    require(AddressUpgradeable.isContract(newImplementation), "NFT: new Implementation must be a contract");
    require(newImplementation != address(0), "NFT: set to zero address");
  }


  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "NFT: caller is not owner nor approved");

    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "NFT: caller is not owner nor approved");

    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _setURI(string memory newuri) internal {
    _uri = newuri;
  }
 
  function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    require(to != address(0), "NFT: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "NFT: insufficient balance for transfer");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);
  }

  function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(ids.length == amounts.length, "NFT: ids & amounts length mismatch");
    require(to != address(0), "NFT: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "NFT: insufficient balance for transfer");
      unchecked {
        _balances[id][from] = fromBalance - amount;
              
      }
       _balances[id][to] += amount;        
    }

    emit TransferBatch(operator, from, to, ids, amounts);
  }

  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    require(to != address(0), "NFT: mint to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
    _balances[id][to] += amount;
   
    emit TransferSingle(operator, address(0), to, id, amount);
  }

  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(to != address(0), "NFT: mint to the zero address");
    require(ids.length == amounts.length, "NFT: ids & amounts length mismatch");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);
  }

  
  function _burn(address from, uint256 id, uint256 amount) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    
    address operator = _msgSender(); 

    _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
    
    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "NFT: burn amount exceeds balance");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);
  }

  function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
    require(from != address(0), "NFT: burn from the zero address");
    require(ids.length == amounts.length, "NFT: ids & amounts length mismatch");
  
    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "NFT: burn amount exceeds balance");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);
  }

  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, "NFT: setting approval status for self");
    _operatorApprovals[owner][operator] = approved;
        
    emit ApprovalForAll(owner, operator, approved);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
 
    operator = _msgSender();
    data = data;
    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
         _totalSupply[ids[i]] += amounts[i];
        
      }
    }
    
    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        uint256 id = ids[i];
        uint256 amount = amounts[i];
        uint256 supply = _totalSupply[id];
        require(supply >= amount, "NFT: burn amount exceeds total Supply");
        unchecked {
          _totalSupply[id] = supply - amount;
        }
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INFTsFactory {

    event proxyDeployed(address indexed propContractAddr);

    function __NFTsFactory_init() external;

    function deployTokens(
        string calldata uri_,  
        address assetWallet,
        address hoa,
        address treasury, 
        string calldata _contractName, 
        uint256 propTaxId
    ) external returns(address);


    function assetContractAddress(address assetWallet) external view returns(address);

    function numOfAssets() external view returns(uint256);

    function allAssets() external view returns(address[] calldata);

    function isPaused() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Utils/ContextUpgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library AddressUpgradeable {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


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


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
pragma solidity ^0.8.0;

import "../Utils/ContextUpgradeable.sol";
import "../Proxies/Initializable.sol";

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {

    event Paused(address account);

    event Unpaused(address account);

    bool internal _paused;


    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }


    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/draft-IERC1822Upgradeable.sol";
import "../Proxies/ERC1967UpgradeUpgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);


    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }


    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;


    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Utils/AddressUpgradeable.sol";


abstract contract Initializable {
  
    bool private _initialized;

    bool private _initializing;


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

  
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ContextUpgradeable {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../Interfaces/IBeaconUpgradeable.sol";
import "../Interfaces/draft-IERC1822Upgradeable.sol";
import "../Utils/AddressUpgradeable.sol";
import "../Utils/StorageSlotUpgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }


    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }


    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;


    event AdminChanged(address previousAdmin, address newAdmin);

    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    event BeaconUpgraded(address indexed beacon);

    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC1822ProxiableUpgradeable {

    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "../Interfaces/IBeaconUpgradeable.sol";
import "../Interfaces/draft-IERC1822Upgradeable.sol";
import "../Utils/AddressUpgradeable.sol";
import "../Utils/StorageSlotUpgradeable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "../Interfaces/IAccessControlUpgradeable.sol";
import "../Utils/ContextUpgradeable.sol";
import "../Utils/StringsUpgradeable.sol";
import "../Utils/ERC165Upgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }


    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }


    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }


    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

 
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringsUpgradeable {
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
pragma solidity ^0.8.0;

import "../Interfaces/IERC165Upgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }


    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../Proxies/Initializable.sol";


contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

 
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MI
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";

interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable{
    
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

interface IERC1155Upgradeable is IERC165Upgradeable{

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event AssetAdded(address walletKey, string[] images, string[] documents);

    event TransferToVault(uint256 tokenid, address indexed transferTo);

    event URI(string value, uint256 indexed id);


    function totalSupply(uint256 id) external view returns(uint256);

    function exists(uint256 id) external view returns(bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function mintNft(uint256 id) external returns(uint256);

    function mintBatchNfts(uint256[] memory ids, uint256[] memory amounts) external returns(uint256[] memory);

    function burnNFT(uint256 id) external;

    function transferToVault(uint256 id, address to) external returns(uint256, address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function assetDetails(
        string[] memory picHash,
        string[] memory physicalAddress,
        string[] memory community,
        string[] memory papers,
        uint256 taxes,
        uint256 insur,
        uint256 maintain,
        uint256 costs,
        string[] memory levels,
        string[] memory extras,
        string[] memory data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC165Upgradeable {
  
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../Interfaces/IERC1155ReceiverUpgradeable.sol";
import "../Utils/ERC165Upgradeable.sol";
import "../Proxies/Initializable.sol";


abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

 
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }


    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }


    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBeaconUpgradeable {
 
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;


interface IAccessControlUpgradeable {
   
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

interface IERC1155ReceiverUpgradeable is IERC165Upgradeable{

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

 
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}