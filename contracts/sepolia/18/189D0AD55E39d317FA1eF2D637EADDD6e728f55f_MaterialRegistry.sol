// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract MaterialRegistry is Ownable {
    mapping(string => Material) registry;
    mapping(string => Material) draftRegistry;
    string[] public materialCodes;
    string[] public draftMaterialCodes;
    address[] approvers;
    struct Material {
        string code;
        string name;
        string description;
        string materialType;
        string category;
        string baseDataModelUri;
        string esgDataModelUri;
    }

    function addApprover(address _approver) public onlyOwner {
        bool isPresent = canApprove(_approver);
        if (!isPresent) {
            approvers.push(_approver);
        }
    }

    function removeApprover(address _approver) public onlyOwner {
        if (approvers.length > 0) {
            for (uint i = 0; i <= approvers.length - 1; i++) {
                if (_approver == approvers[i]) {
                    approvers[i] = approvers[approvers.length - 1];
                    approvers.pop();
                    break;
                }
            }
        }
    }

    function canApprove(address _approver) public view returns (bool) {
        if (approvers.length > 0) {
            for (uint i = 0; i < approvers.length; i++) {
                if (_approver == approvers[i]) {
                    return true;
                }
            }
        }
        return false;
    }

    function getAllApprovers() public view returns (address[] memory) {
        return approvers;
    }

    function addMaterial(
        string memory _code,
        string memory _name,
        string memory _description,
        string memory _materialType,
        string memory _category,
        string memory _baseDataModelUri,
        string memory _esgDataModelUri
    ) public {
        // check if code already exist
        require(
            bytes(registry[_code].name).length == 0,
            "Material with code already present in registry"
        );
        require(
            bytes(draftRegistry[_code].name).length == 0,
            "Material with code already present in draft registry"
        );
        draftRegistry[_code] = Material({
            code: _code,
            name: _name,
            description: _description,
            materialType: _materialType,
            category: _category,
            baseDataModelUri: _baseDataModelUri,
            esgDataModelUri: _esgDataModelUri
        });
        draftMaterialCodes.push(_code);
    }

    function approveMaterial(string memory _code) public returns (bool) {
        require(canApprove(msg.sender), "Not approver");
        require(
            bytes(draftRegistry[_code].name).length != 0,
            "Material with code is not present in draft registry"
        );
        Material memory material = draftRegistry[_code];
        registry[_code] = material;
        delete draftRegistry[_code];
        deleteDraftMaterialCode(_code);
        materialCodes.push(_code);
        return true;
    }

    function deleteDraftMaterialCode(
        string memory _code
    ) private returns (bool) {
        string memory code;
        for (uint i = 0; i < draftMaterialCodes.length; i++) {
            code = draftMaterialCodes[i];
            if (
                keccak256(abi.encodePacked(code)) ==
                keccak256(abi.encodePacked(_code))
            ) {
                draftMaterialCodes[i] = draftMaterialCodes[
                    draftMaterialCodes.length - 1
                ];
                draftMaterialCodes.pop();
                break;
            }
        }
        return true;
    }

    function getMaterialFromDraft(
        string memory _code
    ) public view returns (Material memory) {
        return draftRegistry[_code];
    }

    function getMaterialFromRegistry(
        string memory _code
    ) public view returns (Material memory) {
        return registry[_code];
    }

    function getMaterialList(
        uint256 pageIndex,
        uint256 pageSize
    ) public view returns (Material[] memory) {
        require(pageSize > 0, "Record count should be greater than 0");
        if(materialCodes.length<=0){
            return new Material[](0);
        }
        uint256 totalRecords = materialCodes.length;
        require(pageIndex < totalRecords, "Page index out of range");
        uint256 actualPageSize;
        if (pageIndex + pageSize <= totalRecords) {
            actualPageSize = pageSize;
        } else {
            actualPageSize = totalRecords - pageIndex;
        }
        Material[] memory result = new Material[](actualPageSize);

        for (uint256 i = pageIndex; i < pageIndex + actualPageSize; i++) {
            result[i - pageIndex] = registry[materialCodes[i]];
        }
        return result;
    }

    function getDraftMaterialList(
        uint256 pageIndex,
        uint256 pageSize
    ) public view returns (Material[] memory) {
        require(pageSize > 0, "Record count should be greater than 0");
        if(draftMaterialCodes.length<=0){
            return new Material[](0);
        }
        uint256 totalRecords = draftMaterialCodes.length;
        require(pageIndex < totalRecords, "Page index out of range");
        uint256 actualPageSize;
        if (pageIndex + pageSize <= totalRecords) {
            actualPageSize = pageSize;
        } else {
            actualPageSize = totalRecords - pageIndex;
        }
        Material[] memory result = new Material[](actualPageSize);

        for (uint256 i = pageIndex; i < pageIndex + actualPageSize; i++) {
            result[i - pageIndex] = draftRegistry[draftMaterialCodes[i]];
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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