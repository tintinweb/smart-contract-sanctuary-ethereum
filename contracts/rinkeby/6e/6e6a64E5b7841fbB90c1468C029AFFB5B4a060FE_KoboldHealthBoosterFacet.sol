// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "@solidstate/contracts/access/ownable/Ownable.sol";
import "../libraries/LibKoboldHealthBoosters.sol";
import {KoboldHealthBooster}  from "../interfaces/IKoboldHealthBooster.sol";
import "../libraries/LibAppStorage.sol";
contract KoboldHealthBoosterFacet is Ownable {
    


    function setKoboldHealthBooster(KoboldHealthBooster memory koboldHealthBooster) external onlyOwner  {
        LibKoboldHealthBoosters.setKoboldHealthBooster(koboldHealthBooster);

    }

    //Returns a KoboldHealthBooster
    function getKoboldHealthBooster(uint koboldHealthBoosterId) external view returns(KoboldHealthBooster memory) {
        KoboldHealthBooster memory healthBooster = LibKoboldHealthBoosters.getKoboldHealthBooster(koboldHealthBoosterId);
        if(bytes(healthBooster.name).length == 0 ) revert ("Inexistent healthBooster");
       return healthBooster;
    }
    //User Can Purchase Kobold healthBooster Using Ingot Token
    function purchaseKoboldHealthBooster(uint koboldHealthBoosterId,uint quantity) external {
        address ingotAddress = LibAppStorage.getIngotTokenAddress();
        KoboldHealthBooster memory healthBooster = LibKoboldHealthBoosters.getKoboldHealthBooster(koboldHealthBoosterId);
        IERC20Like(ingotAddress).transferFrom(msg.sender,address(this),healthBooster.price);
        LibKoboldHealthBoosters.purchaseKoboldHealthBooster(msg.sender,koboldHealthBoosterId,quantity);
    }
    //We Get User Balance
    function getKoboldHealthBoosterUserBalance(address user, uint koboldHealthBoosterId) external view returns(uint) {
        return LibKoboldHealthBoosters.getKoboldHealthBoosterBalance(user,koboldHealthBoosterId);
    }

    //Approve And Unapprove healthBooster Spenders... This Will Be Reserved For The Staking Contracts To Use
    function approveKoboldHealthBoosterSpender(address spender) external onlyOwner {
        LibKoboldHealthBoosters.approveKoboldHealthBoosterSpender(spender);
    }
    function unapproveKoboldHealthBoosterSpender(address spender) external onlyOwner {
        LibKoboldHealthBoosters.unapproveKoboldHealthBoosterSpender(spender);
    }

    function queryBatchKoboldHealthBoosters(uint[] calldata koboldHealthBoosterIds) external view returns(KoboldHealthBooster[] memory) {
        return LibKoboldHealthBoosters.queryBatchKoboldHealthBoosters(koboldHealthBoosterIds);
    }
    function queryUserBalanceBatchHealthBoosters(address account,uint[] calldata koboldHealthBoosterIds) external view returns(uint[] memory) {
         return LibKoboldHealthBoosters.queryUserBalanceBatchHealthBoosters(account,koboldHealthBoosterIds);
    }

    

 
}

interface IERC20Like {
    function transferFrom(address from, address to,uint amount) external;
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
    struct KoboldHealthBooster {
        uint price;
        bool isAvailableForPurchase;
        uint healthBoost;
        string name;
    }

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import {KoboldHealthBooster}  from "../interfaces/IKoboldHealthBooster.sol";
library LibKoboldHealthBoosters {
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.health.items");
    event KoboldHealthBoosterUsed(uint indexed koboldTokenId,uint healthToGive);
    struct Storage{
        mapping(uint => KoboldHealthBooster) koboldHealthBoosters;
        mapping(address => mapping(uint => uint)) balanceOfKoboldHealthBoosters;
        mapping(address => bool) approvedKoboldHealthBoosterPurchaser;
        mapping(address => bool) approvedKoboldHealthBoosterSpender;
        uint koboldHealthBoosterIdTracker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function purchaseKoboldHealthBooster(address from,uint koboldHealthBoosterId,uint quantity) internal {
        Storage storage s = getStorage();
        KoboldHealthBooster memory booster = s.koboldHealthBoosters[koboldHealthBoosterId];
        require(booster.isAvailableForPurchase,"Not For Sale");
        // if(booster.quantitySold + quantity > booster.maxQuantity) revert ("Sold Out");
        // s.booster[koboldHealthBoosterId].quantitySold = booster.quantitySold + quantity;
        s.balanceOfKoboldHealthBoosters[from][koboldHealthBoosterId] += quantity;
    }
    function useKoboldHealthBooster(address from,uint koboldTokenId,uint koboldHealthBoosterId,uint quantity) internal {
        Storage storage s = getStorage();
        if(msg.sender != tx.origin) {
        require(s.approvedKoboldHealthBoosterSpender[msg.sender] , "Not Approved Spender");
        }
        if(quantity > s.balanceOfKoboldHealthBoosters[from][koboldHealthBoosterId]) revert ("Kobold healthBooster: Insufficient healthBooster Balance");
        s.balanceOfKoboldHealthBoosters[from][koboldHealthBoosterId] -= quantity;
        emit KoboldHealthBoosterUsed(koboldTokenId,s.koboldHealthBoosters[koboldHealthBoosterId].healthBoost);
    }
    function getKoboldHealthBooster(uint koboldHealthBoosterId) internal view returns(KoboldHealthBooster memory) {
        Storage storage s = getStorage();
        return s.koboldHealthBoosters[koboldHealthBoosterId];
    }
    function queryBatchKoboldHealthBoosters(uint[] calldata koboldHealthBoosterIds) internal view returns(KoboldHealthBooster[] memory) {
            uint len = koboldHealthBoosterIds.length;
            KoboldHealthBooster[]  memory KoboldHealthBoosters = new KoboldHealthBooster[](len);
            for(uint i; i < len;){
                uint id = koboldHealthBoosterIds[i];
                KoboldHealthBoosters[i] = getKoboldHealthBooster(id);
                 unchecked{++i;}
            }
            return KoboldHealthBoosters;
    }

    function queryUserBalanceBatchHealthBoosters(address account,uint[] calldata koboldHealthBoosterIds) internal view returns(uint[] memory) {
            uint len = koboldHealthBoosterIds.length;
            uint[]  memory koboldHealthBoosters = new uint[](len);
            for(uint i; i < len;){
                uint id = koboldHealthBoosterIds[i];
                koboldHealthBoosters[i] = getKoboldHealthBoosterBalance(account,id);
                 unchecked{++i;}
            }
            return koboldHealthBoosters;
    }

    function getKoboldHealthBoosterBalance(address user,uint koboldHealthBoosterId) internal view returns(uint) {
        Storage storage s = getStorage();
        return s.balanceOfKoboldHealthBoosters[user][koboldHealthBoosterId];
    }
    function approveKoboldHealthBoosterSpender(address spender) internal {
        Storage storage s = getStorage();
        s.approvedKoboldHealthBoosterSpender[spender] = true;
    }
    function unapproveKoboldHealthBoosterSpender(address spender) internal {
        Storage storage s = getStorage();
        delete s.approvedKoboldHealthBoosterSpender[spender];
    }
    function setKoboldHealthBooster(KoboldHealthBooster memory koboldHealthBooster) internal {
        Storage storage s = getStorage();
        s.koboldHealthBoosters[s.koboldHealthBoosterIdTracker] = koboldHealthBooster;
        ++s.koboldHealthBoosterIdTracker;
    }

    function overrideExistingHealthBooster(uint healthBoosterId,KoboldHealthBooster memory koboldHealthBooster) internal {
        Storage storage s = getStorage();
          s.koboldHealthBoosters[healthBoosterId] = koboldHealthBooster;
    }
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

import { IERC173 } from '../IERC173.sol';

interface IOwnable is IERC173 {}

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