/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity ^0.8.0;


contract SubscribeRelationship is Ownable{

    struct SubscriptionRelationshipTable {uint artistId; uint closingDate;}
    struct PaymentTypeTable {uint payFee; uint minimumTime;}

    mapping (address => SubscriptionRelationshipTable[]) public ownerToSubcritption;
    mapping (uint => PaymentTypeTable) public payTypeMap;

    event NewSubscriptionRelationship(uint artistId, uint subscribeTime);
    event CommonLog(string tips);

    address erc20;

    constructor(address _erc20) public {
        erc20 = _erc20;
    }

    function replaceErc20(address _erc20) external onlyOwner returns (bool) {
        erc20 = _erc20;
        return true;
    }

    function getDate() public view returns(uint){
        return(block.timestamp);
    }

    function setSubscirbeFee(uint _payType, uint _fee, uint _minimumTime) external onlyOwner returns(bool){
        payTypeMap[_payType].payFee = _fee;
        payTypeMap[_payType].minimumTime = _minimumTime;
        return true;
    }

    function getSubcribeFeeType(uint payType) public view returns(PaymentTypeTable memory) {
        return payTypeMap[payType];
    }

    // 查询订阅者单个艺术家订阅天数view 
    function querySingleArtist(address owner,uint queryArtistId) public view returns(uint) {
        if (ownerToSubcritption[owner].length < 1) {
            return 0;
        }
        for (uint i = 0; i < ownerToSubcritption[owner].length; i++) {
            if (ownerToSubcritption[owner][i].artistId == queryArtistId) {
                if (ownerToSubcritption[owner][i].closingDate > block.timestamp) 
                {return ownerToSubcritption[owner][i].closingDate - block.timestamp;}
                else {
                    return 0;
                }                
            }
        }
        return 0;
    }

    // 查询订阅者下面多个艺术家订阅天数关系
    function queryMultipleArtist(address owner) public view returns(uint[] memory,uint[] memory) {
        uint[] memory artistIdList = new uint[](ownerToSubcritption[owner].length);
        uint[] memory remainList  = new uint[](ownerToSubcritption[owner].length);
        if (ownerToSubcritption[owner].length < 1) {
            return(artistIdList, remainList);
        } else {
            for (uint i = 0; i < ownerToSubcritption[owner].length; i++) {
                if (ownerToSubcritption[owner][i].closingDate > block.timestamp){
                    artistIdList[i] = ownerToSubcritption[owner][i].artistId;
                    remainList[i] = ownerToSubcritption[owner][i].closingDate - block.timestamp;
                } else {
                    artistIdList[i] = ownerToSubcritption[owner][i].artistId;
                    remainList[i] = 0;
                } 
            }
            return(artistIdList, remainList);
        }
    }

    function transferUSDT(address _form, uint256 _amount) public returns(bool){
      bytes32 a =  keccak256("transferFrom(address,address,uint256)");
      bytes4 methodId = bytes4(a);
      bytes memory b =  abi.encodeWithSelector(methodId, _form, 0x4491B99C9349eEAD7073a4795c66396404b7F6B0, _amount);

      emit CommonLog(string(abi.encodePacked("transferUSDT", Strings.toString(_amount))));
      (bool result,) = erc20.call(b);
      return result;
    }

    // 订阅一个artist  payable
    function subscribeArtist(address owner, uint payType, uint subArtistId, uint subscribeTime) public returns(address, uint) {
        // 订阅者首次订阅
        emit CommonLog("here 1");
        uint payAmount = payTypeMap[payType].payFee;
        emit CommonLog("here 2");
        require(subscribeTime == payTypeMap[payType].minimumTime);
        // bool transferResult = transferUSDT(msg.sender, payAmount);
        // // bool transferResult = true;

        // if (transferResult) {
        //     // 转账成功了，开始执行订阅逻辑
        //     // 用户的映射关系第一次建立
        //     if (ownerToSubcritption[owner].length < 1) {
        //     ownerToSubcritption[owner].push(SubscriptionRelationshipTable(subArtistId, block.timestamp + subscribeTime)); 
        //     emit NewSubscriptionRelationship(subArtistId, subscribeTime);
        //     return (owner, subscribeTime);
        //     }

        //     // 订阅者续约的情况
        //     for (uint i = 0; i < ownerToSubcritption[owner].length; i++) {
        //         if (ownerToSubcritption[owner][i].artistId == subArtistId) {
        //             // 防止用户第二次订阅超时很久的情况
        //             if (ownerToSubcritption[owner][i].closingDate >= block.timestamp) {
        //                 ownerToSubcritption[owner][i].closingDate += subscribeTime;     
        //             } else {
        //                 ownerToSubcritption[owner][i].closingDate = block.timestamp + subscribeTime;
        //             }   
        //             emit NewSubscriptionRelationship(subArtistId, subscribeTime);
        //             return (owner, ownerToSubcritption[owner][i].closingDate - block.timestamp);         
        //         }
        //     }

        //     // 订阅者之前有订阅其他艺人，第一次订阅这个艺人
        //     ownerToSubcritption[owner].push(SubscriptionRelationshipTable(subArtistId, block.timestamp + subscribeTime));
        //     emit NewSubscriptionRelationship(subArtistId, subscribeTime);
        //     return (owner, subscribeTime);
        // }
        return (owner, 0);
    }
}