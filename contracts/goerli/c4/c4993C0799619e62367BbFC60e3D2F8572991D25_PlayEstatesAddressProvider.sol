// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title PlayEstates Addresses Provider Contract Interface
/// @dev Main registry of addresses part of or connected to the PlayEstates, including permissioned roles
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations
/// - Owned by the PlayEstates Super Admin
import "../libs/LTypes.sol";
interface IPlayEstatesAddressProvider {
    
    event ContractAddressUpdated(string contractName, address indexed newAddress, uint256 updateddate);
    
    function getNFTMarketplaceContract() external view returns (address, uint256);

    function getPNFTStakingContract() external view returns (address, uint256);

    function getGameEngineContract() external view returns (address, uint256);

    function getOWNKContract() external view returns (address, uint256);

    function getPBRTContract() external view returns (address, uint256);

    function getPEASContract() external view returns (address, uint256);

    function getPEFPContract() external view returns (address, uint256);

    function getPNFTSSContract() external view returns (address, uint256);

    function getPNFTSContract() external view returns (address, uint256);

    // function getPNFTAContract() external view returns (address, uint256);

    // function getPNFTBContract() external view returns (address, uint256);

    // function getPNFTCContract() external view returns (address, uint256);

    function getAllAddresses() external view returns (LTypes.AddressInfo[] memory names);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LDatetime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);
        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDayID(uint256 timestamp) internal pure returns (uint256 dayId) {
        (uint256 year, uint256 month, uint256 day) = timestampToDate(timestamp);
        dayId = (year * 10000) + month * 100 + day;
    }    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LTypes {
    struct AddressInfo {
        bytes32 name;
        address addr;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPlayEstatesAddressProvider.sol";
import "./libs/LDatetime.sol";
import "./libs/LTypes.sol";

/// @title Ink Economy Addresses Provider Contract
/// @dev Main registry of addresses part of or connected to the Ink Economy, including permissioned roles
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations
/// - Owned by the Ink Economy Super Admin
/// @author Ink Finanace

contract PlayEstatesAddressProvider is Ownable, IPlayEstatesAddressProvider {

    /// @notice Emitted when basket address is zero or not contract
    error InkAddressProvider_InvalidAddress(address newAddress);

    using LDatetime for uint256;
    mapping(bytes32 => address) private _addresses;
    mapping(bytes32 => uint256) private _setdates;
    bytes32[] private _names;

    bytes32 private constant CONTRACT_MARKETPLACE = "marketplace";
    bytes32 private constant CONTRACT_PNFTSTAKING = "pnftstaking";
    bytes32 private constant CONTRACT_GAMEENGINE = "gameengine";
    bytes32 private constant TOKEN_PBRT = "pbrt";
    bytes32 private constant TOKEN_PEAS = "peas";
    bytes32 private constant TOKEN_PEFP = "pefp";
    bytes32 private constant TOKEN_OWNK = "ownk";
    bytes32 private constant TOKEN_PNFT_SS = "pnft_ss";
    bytes32 private constant TOKEN_PNFT_S = "pnft_s";    
    bytes32 private constant TOKEN_PNFT_A = "pnft_a";
    bytes32 private constant TOKEN_PNFT_B = "pnft_b";
    bytes32 private constant TOKEN_PNFT_C = "pnft_c";
    bytes32 private constant CONTRACT_AIRDROP_PEAS = "airdrop_peas";

    /// @dev throws if new address is not contract.
    modifier onlyContract(address newAddress) {
        if (!isContract(newAddress))
            revert InkAddressProvider_InvalidAddress(newAddress);
        _;
    }

    constructor() {

    }

    function isContract(address account) 
    internal 
    view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setAddress(bytes32 id, address newAddress) 
    public
    onlyOwner {
        if (_addresses[id] == address(0)) {
            _names.push(id);
        }
        _addresses[id] = newAddress;
        _setdates[id] = block.timestamp.getDayID();
    }

    function getAddress(bytes32 id) 
    public 
    view returns (address, uint256) {
        return (_addresses[id], _setdates[id]);
    }

    function getNFTMarketplaceContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(CONTRACT_MARKETPLACE);
    }

    function setNFTMarketplaceContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(CONTRACT_MARKETPLACE, newAddress);
        emit ContractAddressUpdated("PlayEstates Marketplace", newAddress, _setdates[CONTRACT_MARKETPLACE]);
    }

    function getPNFTStakingContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(CONTRACT_PNFTSTAKING);
    }

    function setPNFTStakingContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(CONTRACT_PNFTSTAKING, newAddress);
        emit ContractAddressUpdated("PlayEstates PnftStaking", newAddress, _setdates[CONTRACT_PNFTSTAKING]);
    }

    function getGameEngineContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(CONTRACT_GAMEENGINE);
    }

    function setGameEngineContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(CONTRACT_GAMEENGINE, newAddress);
        emit ContractAddressUpdated("PlayEstates GameEngine", newAddress, _setdates[CONTRACT_GAMEENGINE]);
    }

    function getOWNKContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(TOKEN_OWNK);
    }

    function setOWNKContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(TOKEN_OWNK, newAddress);
        emit ContractAddressUpdated("PlayEstates OWNK", newAddress, _setdates[TOKEN_OWNK]);
    }

    function getPBRTContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(TOKEN_PBRT);
    }

    function setPBRTContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(TOKEN_PBRT, newAddress);
        emit ContractAddressUpdated("PlayEstates PBRT", newAddress, _setdates[TOKEN_PBRT]);
    }

    function getPEASContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(TOKEN_PEAS);
    }

    function setPEASContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(TOKEN_PEAS, newAddress);
        emit ContractAddressUpdated("PlayEstates PEAS", newAddress, _setdates[TOKEN_PEAS]);
    }

    function getPEFPContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(TOKEN_PEFP);
    }

    function setPEFPContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(TOKEN_PEFP, newAddress);
        emit ContractAddressUpdated("PlayEstates PEFP", newAddress, _setdates[TOKEN_PEFP]);
    }

    function getPNFTSSContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(TOKEN_PNFT_SS);
    }

    function setPNFTSSContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(TOKEN_PNFT_SS, newAddress);
        emit ContractAddressUpdated("PlayEstates PNFT SS", newAddress, _setdates[TOKEN_PNFT_SS]);
    }

    function getPNFTSContract() 
    external 
    override view returns (address, uint256) {
        return getAddress(TOKEN_PNFT_S);
    }

    function setPNFTSContract(address newAddress) 
    public
    onlyOwner onlyContract(newAddress) {
        setAddress(TOKEN_PNFT_S, newAddress);
        emit ContractAddressUpdated("PlayEstates PNFT S", newAddress, _setdates[TOKEN_PNFT_S]);
    }

    function getAllAddresses()
    external 
    override view returns (LTypes.AddressInfo[] memory addresses) {
        addresses = new LTypes.AddressInfo[](_names.length);
        for (uint256 i = 0; i < _names.length; i++) {
            addresses[i].name = _names[i];
            addresses[i].addr = _addresses[_names[i]];
        }
    }
}