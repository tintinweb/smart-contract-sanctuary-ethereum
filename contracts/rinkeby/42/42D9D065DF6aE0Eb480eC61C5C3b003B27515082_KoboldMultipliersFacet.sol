// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "@solidstate/contracts/access/ownable/Ownable.sol";
import "../libraries/LibKoboldMultipliers.sol";
import {KoboldStakingMultiplier}  from "../interfaces/IKoboldMultiplier.sol";
import "../libraries/LibAppStorage.sol";
contract KoboldMultipliersFacet is Ownable {
    


    function setKoboldMultiplier(KoboldStakingMultiplier memory koboldStakingMultiplier) external onlyOwner  {
        LibKoboldMultipliers.setMultiplier(koboldStakingMultiplier);

    }

    //Returns a KoboldStakingMultiplier
    function getKoboldMultiplier(uint koboldMultiplierId) external view returns(KoboldStakingMultiplier memory) {
        KoboldStakingMultiplier memory multiplier = LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
        if(bytes(multiplier.name).length == 0 ) revert ("Inexistent Multiplier");
       return LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
    }
    //User Can Purchase Kobold Multiplier Using Ingot Token
    function purchaseKoboldMultiplier(uint koboldMultiplierId,uint quantity) external {
        address ingotAddress = LibAppStorage.getIngotTokenAddress();
        KoboldStakingMultiplier memory multiplier = LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
        IERC20Like(ingotAddress).transferFrom(msg.sender,address(this),multiplier.price);
        LibKoboldMultipliers.purchaseMultiplier(msg.sender,koboldMultiplierId,quantity);
    }
    //We Get User Balance
    function getKoboldMultiplierUserBalance(address user, uint koboldMultiplerId) external view returns(uint) {
        return LibKoboldMultipliers.getUserBalance(user,koboldMultiplerId);
    }

    //Approve And Unapprove Multiplier Spenders... This Will Be Reserved For The Staking Contracts To Use
    function approveKoboldMultiplierSpender(address spender) external onlyOwner {
        LibKoboldMultipliers.approveSpender(spender);
    }
    function unapproveKoboldMultiplierSpender(address spender) external onlyOwner {
        LibKoboldMultipliers.unapproveSpender(spender);
    }

    function queryBatchKoboldMultipliers(uint[] calldata koboldMultiplierIds) external view returns(KoboldStakingMultiplier[] memory) {
        return LibKoboldMultipliers.queryBatchKoboldMultipliers(koboldMultiplierIds);
    }
    function queryUserBalanceBatchMultipliers(address account,uint[] calldata koboldMultiplierIds) external view returns(uint[] memory) {
         return LibKoboldMultipliers.queryUserBalanceBatchMultipliers(account,koboldMultiplierIds);
    }

    

 
}

interface IERC20Like {
    function transferFrom(address from, address to,uint amount) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import {KoboldStakingMultiplier}  from "../interfaces/IKoboldMultiplier.sol";
library LibKoboldMultipliers {
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.multipliers");

    struct Storage{
        mapping(uint => KoboldStakingMultiplier) multipliers;
        mapping(address => mapping(uint => uint)) balanceOf;
        mapping(address => bool) approvedPurchaser;
        mapping(address => bool) approvedSpender;
        uint koboldMultiplierIdTracker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function purchaseMultiplier(address from,uint koboldMultiplierId,uint quantity) internal {
        Storage storage s = getStorage();
        KoboldStakingMultiplier memory multiplier = s.multipliers[koboldMultiplierId];
        require(multiplier.isAvailableForPurchase,"Not For Sale");
        if(multiplier.quantitySold + quantity > multiplier.maxQuantity) revert ("Sold Out");
        s.multipliers[koboldMultiplierId].quantitySold = multiplier.quantitySold + quantity;
        s.balanceOf[from][koboldMultiplierId] += quantity;
    }
    function spendMultiplier(address from,uint koboldMultiplierId,uint quantity) internal {
        Storage storage s = getStorage();
        if(msg.sender != tx.origin) {
        require(s.approvedSpender[msg.sender] , "Not Approved Spender");
        }
        if(quantity > s.balanceOf[from][koboldMultiplierId]) revert ("Kobold Multiplier: Insufficient Multiplier Balance");
        s.balanceOf[from][koboldMultiplierId] -= quantity;
    }
    function getKoboldMultiplier(uint koboldMultiplierId) internal view returns(KoboldStakingMultiplier memory) {
        Storage storage s = getStorage();
        return s.multipliers[koboldMultiplierId];
    }
    function queryBatchKoboldMultipliers(uint[] calldata koboldMultiplierIds) internal view returns(KoboldStakingMultiplier[] memory) {
            uint len = koboldMultiplierIds.length;
            KoboldStakingMultiplier[]  memory koboldStakingMultipliers = new KoboldStakingMultiplier[](len);
            for(uint i; i < len;){
                uint id = koboldMultiplierIds[i];
                koboldStakingMultipliers[i] = getKoboldMultiplier(id);
                 unchecked{++i;}
            }
            return koboldStakingMultipliers;
    }

    function queryUserBalanceBatchMultipliers(address account,uint[] calldata koboldMultiplierIds) internal view returns(uint[] memory) {
            uint len = koboldMultiplierIds.length;
            uint[]  memory koboldStakingMultipliers = new uint[](len);
            for(uint i; i < len;){
                uint id = koboldMultiplierIds[i];
                koboldStakingMultipliers[i] = getUserBalance(account,id);
                 unchecked{++i;}
            }
            return koboldStakingMultipliers;
    }

    function getUserBalance(address user,uint koboldMultiplierId) internal view returns(uint) {
        Storage storage s = getStorage();
        return s.balanceOf[user][koboldMultiplierId];
    }
    function approveSpender(address spender) internal {
        Storage storage s = getStorage();
        s.approvedSpender[spender] = true;
    }
    function unapproveSpender(address spender) internal {
        Storage storage s = getStorage();
        delete s.approvedSpender[spender];
    }
    function setMultiplier(KoboldStakingMultiplier memory koboldStakingMultiplier) internal {
        Storage storage s = getStorage();
        s.multipliers[s.koboldMultiplierIdTracker] = koboldStakingMultiplier;
        ++s.koboldMultiplierIdTracker;
    }

    function overrideExistingMultiplier(uint multiplierId,KoboldStakingMultiplier memory koboldStakingMultiplier) internal {
        Storage storage s = getStorage();
          s.multipliers[multiplierId] = koboldStakingMultiplier;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;   
import {AppStorage} from "../interfaces/IAppStorage.sol";
library LibAppStorage {

    bytes32 internal constant NAMESPACE = keccak256("titanforge.items.diamond.appstorage");

       function appStorage() internal pure returns(AppStorage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function setIngotTokenAddress(address _ingot) internal {
        AppStorage storage s = appStorage();
        s.ingotTokenAddress = _ingot;
    }
    function setKoboldAddress(address _koboldAddress) internal {
        AppStorage storage s = appStorage();
        s.koboldAddress = _koboldAddress;
    }
    function setTitanAddress(address _titanAddress) internal {
        AppStorage storage s = appStorage();
        s.titanAddress = _titanAddress;
    }

    function getIngotTokenAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.ingotTokenAddress;
    }
        function getKoboldAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.koboldAddress;
    }
        function getTitanAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.titanAddress;
    }

}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;   
    struct KoboldStakingMultiplier {
        uint price;
        uint multiplier; //5  = 5%
        bool isAvailableForPurchase;
        uint maxQuantity;
        uint quantitySold;
        string name;
    }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;  
struct AppStorage {
        address ingotTokenAddress;
        address koboldAddress;
        address titanAddress;
    }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IERC173 } from '../IERC173.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(msg.sender == _owner(), 'Ownable: sender must be owner');
        _;
    }

    modifier onlyTransitiveOwner() {
        require(
            msg.sender == _transitiveOwner(),
            'Ownable: sender must be transitive owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address) {
        address owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                return owner;
            }
        }

        return owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}