pragma solidity 0.5.8;

import "./ReclaimTokens.sol";
import "./interfaces/IFeatureRegistry.sol";

/**
 * @title Registry for managing polymath feature switches
 */
contract FeatureRegistry is IFeatureRegistry, ReclaimTokens {
    mapping(bytes32 => bool) public featureStatus;

    /**
     * @notice Get the status of a feature
     * @param _nameKey is the key for the feature status mapping
     * @return bool
     */
    function getFeatureStatus(string calldata _nameKey) external view returns(bool) {
        bytes32 key = keccak256(bytes(_nameKey));
        return featureStatus[key];
    }

    /**
     * @notice change a feature status
     * @dev feature status is set to false by default
     * @param _nameKey is the key for the feature status mapping
     * @param _newStatus is the new feature status
     */
    function setFeatureStatus(string calldata _nameKey, bool _newStatus) external onlyOwner {
        bytes32 key = keccak256(bytes(_nameKey));
        require(featureStatus[key] != _newStatus, "Status unchanged");
        emit ChangeFeatureStatus(_nameKey, _newStatus);
        featureStatus[key] = _newStatus;
    }

}

pragma solidity 0.5.8;

/**
 * @title Interface for managing polymath feature switches
 */
interface IFeatureRegistry {

    event ChangeFeatureStatus(string _nameKey, bool _newStatus);

    /**
     * @notice change a feature status
     * @dev feature status is set to false by default
     * @param _nameKey is the key for the feature status mapping
     * @param _newStatus is the new feature status
     */
    function setFeatureStatus(string calldata _nameKey, bool _newStatus) external;

    /**
     * @notice Get the status of a feature
     * @param _nameKey is the key for the feature status mapping
     * @return bool
     */
    function getFeatureStatus(string calldata _nameKey) external view returns(bool hasFeature);

}

pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/**
 * @title Utility contract to allow owner to retreive any ERC20 sent to the contract
 */
contract ReclaimTokens is Ownable {
    /**
    * @notice Reclaim all ERC20Basic compatible tokens
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Transfer failed");
    }
}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}