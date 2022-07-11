/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.15;
pragma abicoder v2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IVRFProviderViewOnly {
    function oracleScriptID() external view returns(uint64);
    function minCount() external view returns(uint8);
    function askCount() external view returns(uint8);
}

contract VRFLens is Ownable {

    IVRFProviderViewOnly public provider;

    constructor(IVRFProviderViewOnly _provider) {
        provider = _provider;
    }

    function setProvider(IVRFProviderViewOnly _provider) external onlyOwner {
        provider = _provider;
    }

    function getTaskSingle(uint64 nonce) public view returns(bool, bytes memory) {
        bytes memory payload = abi.encodeWithSignature("tasks(uint64)", nonce);
        (bool success, bytes memory returnData) = address(provider).staticcall(payload);
        return (success, returnData);
    }

    function getTasksBulk(uint64[] calldata nonces) public view returns(bytes[] memory) {
        uint256 len = nonces.length;
        bytes[] memory tasks = new bytes[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool ok, bytes memory data) = getTaskSingle(nonces[i]);
            require(ok, "VRFLens: Fail to getTaskSingle");
            tasks[i] = data;
        }
        return tasks;
    }

    function getProviderConfig() external view returns(uint64, uint8, uint8) {
        return (provider.oracleScriptID(), provider.minCount(), provider.askCount());
    }
}