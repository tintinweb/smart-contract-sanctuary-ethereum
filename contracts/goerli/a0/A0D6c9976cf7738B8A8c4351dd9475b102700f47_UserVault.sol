// SPDX-License-Identifier: GPL-3.0-or-later
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
        mapping(bytes32 => uint) _indexes;
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
        uint valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint toDeleteIndex = valueIndex - 1;
            uint lastIndex = set._values.length - 1;

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
    function _length(Set storage set) private view returns (uint) {
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
    function _at(Set storage set, uint index) private view returns (bytes32) {
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
    function addValue(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint) {
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
    function at(AddressSet storage set, uint index) internal view returns (address) {
        return address(uint160(uint(_at(set._inner, index))));
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
}

pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";
import "../utils/DesynOwnable.sol";
import "../libraries/SmartPoolManager.sol";
// Contracts
pragma experimental ABIEncoderV2;

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);

    function isCompletedCollect() external view returns (bool);
}

interface IToken {
    function decimals() external view returns (uint);
}

interface IDesynOwnable {
    function adminList(address adr) external view returns (bool);

    function getController() external view returns (address);

    function getOwners() external view returns (address[] memory);

    function getOwnerPercentage() external view returns (uint[] memory);

    function allOwnerPercentage() external view returns (uint);
}

interface IDSProxy {
    function owner() external view returns (address);
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract UserVault is DesynOwnable {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    ICRPFactory crpFactory;
    address public vaultAddress;

    event LOGVaultAdr(address indexed manager, address indexed caller);

    struct ClaimTokenInfo {
        address token;
        uint decimals;
        uint amount;
    }

    struct ClaimRecordInfo {
        uint time;
        ClaimTokenInfo[] tokens;
    }

    // pool of tokens
    struct PoolTokens {
        address[] tokenList;
        address[] issueTokens;
        address[] redeemTokens;
        address[] perfermanceTokens;
        uint[] managerAmount;
        uint[] issueAmount;
        uint[] redeemAmount;
        uint[] perfermanceAmount;
    }

    struct PoolStatus {
        bool couldManagerClaim;
        bool isBlackList;
        bool isSetParams;
        SmartPoolManager.KolPoolParams kolPoolConfig;
    }

    // kol list
    struct KolUserInfo {
        address userAdr;
        uint[] userAmount;
    }

    //pool=>manager
    mapping(address => address) public pool_manager;

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) poolsStatus;

    //history record
    mapping(address => uint) public record_number;
    mapping(address => mapping(uint => ClaimRecordInfo)) public record_List;

    //pool => tokenList
    mapping(address => address[]) public kol_token_list;

    //pool => initTotalAmount[]
    mapping(address => uint) public init_totalAmount_list;
    //pool => manager => uint
    mapping(address => mapping(address => uint)) public manager_claimed_list;
    mapping(address => uint) public pool_manangerHasClaimed;

    //pool => kol[]
    mapping(address => EnumerableSet.AddressSet) kols_list;
    //pool => kol =>uint
    mapping(address => mapping(address => uint)) public kol_claimed_list;
    //pool => kol => totalAmount[]
    mapping(address => mapping(address => uint[])) public kol_totalAmount_list;
    // pool => kol => KolUserInfo[]
    mapping(address => mapping(address => KolUserInfo[])) public kol_user_info;

    //pool => user => index
    mapping(address => mapping(address => uint)) public user_index_list;
    // pool => user => kol
    mapping(address => mapping(address => address)) public user_kol_list;

    uint public RATIO_TOTAL = 100;

    receive() external payable {}

    function depositToken(
        address pool,
        uint types,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external onlyVault {
        require(poolTokens.length == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        if (pool_manager[pool] == address(0)) {
            pool_manager[pool] = ICRPPool(pool).getController();
        }
        (address[] memory _pool_tokenList, uint[] memory _pool_tokenAmount) = createTokenParams(pool, types);
        (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) = communaldepositToken(poolTokens, tokensAmount, pool, _pool_tokenList, _pool_tokenAmount);
        setResult(pool, types, new_pool_tokenList, new_pool_tokenAmount);
        poolsStatus[pool].couldManagerClaim = true;
    }

    function claimKolReward(address pool) external {
        try IVault(vaultAddress).managerClaim(pool) {} catch {}
        if (this.isClosePool(pool)) {
            require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
            require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
            uint totalAmount = this.kolUnClaimAmount(pool, msg.sender);
            require(totalAmount > 0, "ERR_HAS_NO_REWARD");

            kol_claimed_list[pool][msg.sender] += totalAmount;
            if (address(msg.sender).isContract()) {
                IERC20(kol_token_list[pool][0]).transfer(IDSProxy(msg.sender).owner(), totalAmount);
            } else {
                IERC20(kol_token_list[pool][0]).transfer(msg.sender, totalAmount);
            }
        }
    }
    // for the mananger
    // function managerClaim(address pool) external {
    //     try IVault(vaultAddress).managerClaim(pool) {} catch {}
    //     if (this.isClosePool(pool)) {
    //         require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
    //         require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
    //         require(IDesynOwnable(pool).adminList(msg.sender) || IDesynOwnable(pool).getController() == msg.sender, "Not Owner");
    //         uint totalAmount = this.getUnManagerReward(pool, msg.sender);
    //         require(totalAmount > 0, "ERR_HAS_NO_REWARD");
    //         poolsStatus[pool].couldManagerClaim = false;
    //         manager_claimed_list[pool][msg.sender] += totalAmount; // for the manager
            
    //         uint newIndex = record_number[pool].add(1);
    //         address issueToken = kol_token_list[pool][0];
    //         address receiver = address(msg.sender).isContract()? IDSProxy(msg.sender).owner(): msg.sender;

    //         ClaimTokenInfo memory recordToken;
    //         recordToken.decimals = IERC20(issueToken).decimals();
    //         recordToken.token = issueToken;
    //         recordToken.amount = totalAmount;
            
    //         IERC20(issueToken).transfer(receiver, totalAmount);
    //         // record manager claim history
    //         record_number[pool] = newIndex;
    //         record_List[pool][newIndex].time = block.timestamp;
    //         record_List[pool][newIndex].tokens.push(recordToken);
    //     }
    // }
    // for all manager
    function managerClaim(address pool) external {
        try IVault(vaultAddress).managerClaim(pool) {} catch {}
        if (this.isClosePool(pool)) {
            require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
            require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
            require(IDesynOwnable(pool).adminList(msg.sender) || IDesynOwnable(pool).getController() == msg.sender, "Not Owner");
            uint totalAmount = this.getUnManagerReward(pool); // for all manager unclaim
            require(totalAmount > 0, "ERR_HAS_NO_REWARD");
            poolsStatus[pool].couldManagerClaim = false;

            pool_manangerHasClaimed[pool] += totalAmount; // for all manager
            
            uint newIndex = record_number[pool].add(1);
            address issueToken = kol_token_list[pool][0];

            ClaimTokenInfo memory recordToken;
            recordToken.decimals = IERC20(issueToken).decimals();
            recordToken.token = issueToken;
            recordToken.amount = totalAmount;
            
            _transferHandle(pool, msg.sender, issueToken, totalAmount);
            // record manager claim history
            record_number[pool] = newIndex;
            record_List[pool][newIndex].time = block.timestamp;
            record_List[pool][newIndex].tokens.push(recordToken);
        }
    }

    function _transferHandle(
        address pool,
        address manager_address,
        address t,
        uint balance
    ) internal {
        address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
        uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
        uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

        for (uint k = 0; k < managerAddressList.length; k++) {
            address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
            IERC20(t).transfer(reciver, balance.mul(ownerPercentage[k]).div(allOwnerPercentage));
        }
    }

    function managerClaimRecordList(address pool) external view returns (ClaimRecordInfo[] memory claimRecordInfos) {
        uint num = record_number[pool];
        ClaimRecordInfo[] memory records = new ClaimRecordInfo[](num);
        for (uint i = 1; i < num + 1; i++) {
            ClaimRecordInfo memory record;
            record = record_List[pool][i];
            records[i.sub(1)] = record;
        }
        return records;
    }

    // for all manager
    function getManagerReward(address pool) external view returns (uint) {
        return this.getPoolAllFee(pool).sub(this.getAllKolReward(pool));
    }
    // for all manager
    function getUnManagerReward(address pool) external view returns (uint) {
        return this.getManagerReward(pool).sub(pool_manangerHasClaimed[pool]);
    }
    // for all manager
    function managerClaimList(address pool) external view returns (ClaimTokenInfo[1] memory) {
        ClaimTokenInfo memory token;
        address issueToken = kol_token_list[pool][0];

        token.token = issueToken;
        token.amount = this.getUnManagerReward(pool);
        token.decimals = IERC20(issueToken).decimals();
        ClaimTokenInfo[1] memory tokens = [token]; // for front-end call same as vault
        return tokens;
    }

    // for the manager
    function getManagerReward(address pool, address maragerAdr) external view returns (uint) {
        uint totalAmount = this.getManagerReward(pool);
        address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
        uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
        uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();
        for (uint k = 0; k < managerAddressList.length; k++) {
            if (maragerAdr == managerAddressList[k]) {
                return totalAmount.mul(ownerPercentage[k]).div(allOwnerPercentage);
            }
        }
    }
    // for the manager
    function getUnManagerReward(address pool, address maragerAdr) external view returns (uint) {
        return this.getManagerReward(pool, maragerAdr).sub(manager_claimed_list[pool][maragerAdr]);
    }
    // for the manager
    // function managerClaimList(address pool, address userProxy) external view returns (ClaimTokenInfo[1] memory) {
    //     ClaimTokenInfo memory token;
    //     address issueToken = kol_token_list[pool][0];

    //     token.token = issueToken;
    //     token.amount = this.getUnManagerReward(pool, userProxy);
    //     token.decimals = IERC20(issueToken).decimals();
    //     ClaimTokenInfo[1] memory tokens = [token]; // for front-end call same as vault
    //     return tokens;
    // }

    function getPoolAllFee(address pool) external view returns (uint totalAmount) {
        PoolTokens memory tokens = poolsTokens[pool];
        totalAmount += tokens.managerAmount.length > 0 ? tokens.managerAmount[0] : 0;
        totalAmount += tokens.issueAmount.length > 0 ? tokens.issueAmount[0] : 0;
        totalAmount += tokens.redeemAmount.length > 0 ? tokens.redeemAmount[0] : 0;
        totalAmount += tokens.perfermanceAmount.length > 0 ? tokens.perfermanceAmount[0] : 0;
    }

    function getAllKolReward(address pool) external view returns (uint totalAmount) {
        EnumerableSet.AddressSet storage list = kols_list[pool];
        uint len = list.length();
        for (uint i = 0; i < len; i++) {
            totalAmount += this.kolClaimTotal(pool, list.at(i));
        }
    }

    function kolUnClaimAmount(address pool, address kol) external view returns (uint) {
        uint totalClaim = this.kolClaimTotal(pool, kol);
        uint totalClaimed = kol_claimed_list[pool][kol];
        return totalClaim.sub(totalClaimed);
    }

    function kolClaimTotal(address pool, address kol) external view returns (uint) {
        uint totalFee;
        if (kol_totalAmount_list[pool][kol].length == 0) return totalFee;
        totalFee = totalFee.add(this._computeReward(pool, kol, 0));
        totalFee = totalFee.add(this._computeReward(pool, kol, 1));
        totalFee = totalFee.add(this._computeReward(pool, kol, 2));
        totalFee = totalFee.add(this._computeReward(pool, kol, 3));
        totalFee = totalFee.mul(kol_totalAmount_list[pool][kol][0]).div(init_totalAmount_list[pool]);
        return totalFee;
    }

    function _computeReward(
        address pool,
        address kol,
        uint types
    ) external view returns (uint) {
        uint kolTotalAmount = kol_totalAmount_list[pool][kol].length > 0 ? kol_totalAmount_list[pool][kol][0] : 0;
        SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;
        uint totalFee;

        PoolTokens memory tokens = poolsTokens[pool];

        if(kolTotalAmount == 0){
            return 0;
        }

        if (types == 0 && tokens.managerAmount.length > 0) {
            totalFee = tokens.managerAmount[0].mul(levelJudge(kolTotalAmount, params.managerFee)).div(RATIO_TOTAL);
        }  
        if (types == 1 && tokens.issueAmount.length > 0) {
            totalFee = tokens.issueAmount[0].mul(levelJudge(kolTotalAmount, params.issueFee)).div(RATIO_TOTAL);
        } 
        if (types == 2 && tokens.redeemAmount.length > 0) {
            totalFee = tokens.redeemAmount[0].mul(levelJudge(kolTotalAmount, params.redeemFee)).div(RATIO_TOTAL);
        }  
        if (types == 3 && tokens.perfermanceAmount.length > 0) {
            totalFee = tokens.perfermanceAmount[0].mul(levelJudge(kolTotalAmount, params.perfermanceFee)).div(RATIO_TOTAL);
        }
        return totalFee;
    }

    function levelJudge(uint amount, SmartPoolManager.feeParams memory _feeParams) internal view returns (uint) {
        for (uint i = 0; i < 4; i++) {
            if (i == 0) {
                if (_feeParams.firstLevel.level <= amount && amount < _feeParams.secondLevel.level) {
                    return _feeParams.firstLevel.ratio;
                }
            }
            if (i == 1) {
                if (_feeParams.secondLevel.level <= amount && amount < _feeParams.thirdLevel.level) {
                    return _feeParams.secondLevel.ratio;
                }
            }
            if (i == 2) {
                if (_feeParams.thirdLevel.level <= amount && amount < _feeParams.fourLevel.level) {
                    return _feeParams.thirdLevel.ratio;
                }
            }
            if (i == 3) {
                if (_feeParams.fourLevel.level <= amount) {
                    return _feeParams.fourLevel.ratio;
                }
            }
        }
    }

    function setResult(
        address pool,
        uint types,
        address[] memory new_pool_tokenList,
        uint[] memory new_pool_tokenAmount
    ) internal {
        PoolTokens storage tokens = poolsTokens[pool];
        if (types == 0) {
            tokens.tokenList = new_pool_tokenList;
            tokens.managerAmount = new_pool_tokenAmount;
        }  
        if (types == 1) {
            tokens.issueTokens = new_pool_tokenList;
            tokens.issueAmount = new_pool_tokenAmount;
        }  
        if (types == 2) {
            tokens.redeemTokens = new_pool_tokenList;
            tokens.redeemAmount = new_pool_tokenAmount;
        }  
        if (types == 3) {
            tokens.perfermanceTokens = new_pool_tokenList;
            tokens.perfermanceAmount = new_pool_tokenAmount;
        }
    }

    function createTokenParams(address pool, uint types) internal view returns (address[] memory _pool_tokenList, uint[] memory _pool_tokenAmount) {
        require(0 <= types && types < 4, "ERR_TYPES");
        
        PoolTokens memory tokens = poolsTokens[pool];
        if (types == 0) {
            _pool_tokenList = tokens.tokenList;
            _pool_tokenAmount = tokens.managerAmount;
        }
        if (types == 1) {
            _pool_tokenList = tokens.issueTokens;
            _pool_tokenAmount = tokens.issueAmount;
        }
        if (types == 2) {
            _pool_tokenList = tokens.redeemTokens;
            _pool_tokenAmount = tokens.redeemAmount;
        }
        if (types == 3) {
            _pool_tokenList = tokens.perfermanceTokens;
            _pool_tokenAmount = tokens.perfermanceAmount;
        }
    }

    function communaldepositToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        address poolAdr,
        address[] memory _pool_tokenList,
        uint[] memory _pool_tokenAmount
    ) internal view returns (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) {
        uint len = poolTokens.length;
        //old
        //new
        new_pool_tokenList = new address[](len);
        new_pool_tokenAmount = new uint[](len);
        if ((_pool_tokenList.length == _pool_tokenAmount.length && _pool_tokenList.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < len; i++) {
                // uint tokenBalance = tokensAmount[i];
                new_pool_tokenList[i] = poolTokens[i];
                new_pool_tokenAmount[i] = tokensAmount[i];
            }
        } else {
            for (uint k = 0; k < len; k++) {
                if (_pool_tokenList[k] == poolTokens[k]) {
                    uint tokenBalance = tokensAmount[k];
                    new_pool_tokenList[k] = poolTokens[k];
                    new_pool_tokenAmount[k] = _pool_tokenAmount[k].add(tokenBalance);
                }
            }
        }
        return (new_pool_tokenList, new_pool_tokenAmount);
    }

    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external {
        address pool = msg.sender;
        uint len = poolTokens.length;
        require(len == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        if (kol_token_list[pool].length == 0) {
            kol_token_list[pool] = poolTokens;
        }
        address newKol = user_kol_list[pool][user];
        if (user_kol_list[pool][user] == address(0)) {
            user_kol_list[pool][user] = kol;
            if (!kols_list[pool].contains(kol)) {
                kols_list[pool].addValue(kol);
            }
            newKol = kol;
        }
        require(newKol != address(0), "ERR_INVALID_KOL_ADDRESS");
        //total amount record
        init_totalAmount_list[pool] = init_totalAmount_list[pool].add(tokensAmount[0]);
        uint[] memory totalAmounts = new uint[](len);
        for (uint i = 0; i < len; i++) {
            if (kol_totalAmount_list[pool][newKol].length == 0) {
                totalAmounts[i] = tokensAmount[i];
            } else {
                totalAmounts[i] = tokensAmount[i].add(kol_totalAmount_list[pool][newKol][i]);
            }
        }
        kol_totalAmount_list[pool][newKol] = totalAmounts;
        //kol user info record
        KolUserInfo[] storage userInfoArray = kol_user_info[pool][newKol];
        uint index = user_index_list[pool][user];
        if (index == 0) {
            KolUserInfo memory userInfo;
            userInfo.userAdr = user;
            userInfo.userAmount = tokensAmount;
            userInfoArray.push(userInfo);
            user_index_list[pool][user] = userInfoArray.length;
        } else {
            KolUserInfo storage userInfo = kol_user_info[pool][newKol][index - 1];
            for (uint a = 0; a < userInfo.userAmount.length; a++) {
                userInfo.userAmount[a] = userInfo.userAmount[a].add(tokensAmount[a]);
            }
        }
    }

    function setPoolParams(address pool, SmartPoolManager.KolPoolParams memory _poolParams) external onlyCrpFactory {
        PoolStatus storage status = poolsStatus[pool];
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(!status.isSetParams, "ERR_HAS_SETED");

        status.isSetParams = true;
        status.kolPoolConfig = _poolParams;
    }

    function isClosePool(address pool) external view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function getKolsAdr(address pool) external view returns (address[] memory) {
        return kols_list[pool].values();
    }

    function getPoolUserList(address pool) external view returns (address[] memory tokenList) {
        return kol_token_list[pool];
    }

    function getPoolUserKolAdr(address pool, address user) external view returns (address tokenAddress) {
        return user_kol_list[pool][user];
    }

    function getPoolKolUserInfo(address pool, address kol) external view returns (KolUserInfo[] memory info) {
        return kol_user_info[pool][kol];
    }

    function getPoolKolTotalAmounts(address pool, address kol) external view returns (uint[] memory) {
        return kol_totalAmount_list[pool][kol];
    }

    function poolManagerTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].tokenList;
    }

    function poolManagerTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].managerAmount;
    }

    function poolIssueTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].issueTokens;
    }

    function poolRedeemTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].redeemTokens;
    }

    function poolIssueTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].issueAmount;
    }

    function poolRedeemTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].redeemAmount;
    }

    function poolPerfermanceTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].perfermanceTokens;
    }

    function poolPerfermanceTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].perfermanceAmount;
    }

    function getManagerClaimBool(address pool) external view returns (bool bools) {
        bools = poolsStatus[pool].couldManagerClaim;
    }

    function setBlackList(address pool, bool bools) external onlyOwner {
        poolsStatus[pool].isBlackList = bools;
    }

    function setCrpFactory(address adr) external onlyOwner {
        crpFactory = ICRPFactory(adr);
    }

    function adminClaimToken(
        address token,
        address user,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(user, amount);
    }

    function getBNB() external payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setVaultAdr(address adr) external onlyOwner {
        require(adr != address(0), "ERR_INVALID_VAULT_ADDRESS");
        vaultAddress = adr;
        emit LOGVaultAdr(adr, msg.sender);
    }

    modifier onlyCrpFactory() {
        require(address(crpFactory) == msg.sender, "ERR_NOT_CRP_FACTORY");
        _;
    }

    modifier onlyVault() {
        require(vaultAddress == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the decimals of tokens
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IERC20.sol";
import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IBFactory.sol"; // unused
import "./DesynSafeMath.sol"; // unused
import "./SafeApprove.sol";

/**
 * @author Desyn Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    using SafeApprove for IERC20;

    //kol pool params
    struct levelParams {
        uint level;
        uint ratio;
    }

    struct feeParams {
        levelParams firstLevel;
        levelParams secondLevel;
        levelParams thirdLevel;
        levelParams fourLevel;
    }
    struct KolPoolParams {
        feeParams managerFee;
        feeParams issueFee;
        feeParams redeemFee;
        feeParams perfermanceFee;
    }

    // Type declarations
    enum Etypes {
        OPENED,
        CLOSED
    }

    enum Period {
        HALF,
        ONE,
        TWO
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */
    struct Status {
        uint collectPeriod;
        uint collectEndTime;
        uint closurePeriod;
        uint closureEndTime;
        uint upperCap;
        uint floorCap;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        uint startClaimFeeTime;
    }

    struct PoolParams {
        // Desyn Pool Token (representing shares of the pool)
        string poolTokenSymbol;
        string poolTokenName;
        // Tokens inside the Pool
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        Etypes etype;
    }

    struct PoolTokenRange {
        uint bspFloor;
        uint bspCap;
    }

    struct Fund {
        uint etfAmount;
        uint fundAmount;
    }

    function initRequire(
        uint swapFee,
        uint managerFee,
        uint issueFee,
        uint redeemFee,
        uint perfermanceFee,
        uint tokenBalancesLength,
        uint tokenWeightsLength,
        uint constituentTokensLength,
        bool initBool
    ) external pure {
        // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
        // (and be unrecoverable if they don't have permission set to change it)
        // Most likely to fail, so check first
        require(!initBool, "Init fail");
        require(swapFee >= DesynConstants.MIN_FEE, "ERR_INVALID_SWAP_FEE");
        require(swapFee <= DesynConstants.MAX_FEE, "ERR_INVALID_SWAP_FEE");
        require(managerFee >= DesynConstants.MANAGER_MIN_FEE, "ERR_INVALID_MANAGER_FEE");
        require(managerFee <= DesynConstants.MANAGER_MAX_FEE, "ERR_INVALID_MANAGER_FEE");
        require(issueFee >= DesynConstants.ISSUE_MIN_FEE, "ERR_INVALID_ISSUE_MIN_FEE");
        require(issueFee <= DesynConstants.ISSUE_MAX_FEE, "ERR_INVALID_ISSUE_MAX_FEE");
        require(redeemFee >= DesynConstants.REDEEM_MIN_FEE, "ERR_INVALID_REDEEM_MIN_FEE");
        require(redeemFee <= DesynConstants.REDEEM_MAX_FEE, "ERR_INVALID_REDEEM_MAX_FEE");
        require(perfermanceFee >= DesynConstants.PERFERMANCE_MIN_FEE, "ERR_INVALID_PERFERMANCE_MIN_FEE");
        require(perfermanceFee <= DesynConstants.PERFERMANCE_MAX_FEE, "ERR_INVALID_PERFERMANCE_MAX_FEE");

        // Arrays must be parallel
        require(tokenBalancesLength == constituentTokensLength, "ERR_START_BALANCES_MISMATCH");
        require(tokenWeightsLength == constituentTokensLength, "ERR_START_WEIGHTS_MISMATCH");
        // Cannot have too many or too few - technically redundant, since BPool.bind() would fail later
        // But if we don't check now, we could have a useless contract with no way to create a pool

        require(constituentTokensLength >= DesynConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(constituentTokensLength <= DesynConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        // There are further possible checks (e.g., if they use the same token twice), but
        // we can let bind() catch things like that (i.e., not things that might reasonably work)
    }

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenA - token to sell
     * @param tokenB - token to buy
     */
    function rebalance(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external {
        uint currentWeightA = bPool.getDenormalizedWeight(tokenA);
        uint currentBalanceA = bPool.getBalance(tokenA);
        // uint currentWeightB = bPool.getDenormalizedWeight(tokenB);

        require(deltaWeight <= currentWeightA, "ERR_DELTA_WEIGHT_TOO_BIG");

        // deltaBalance = currentBalance * (deltaWeight / currentWeight)
        uint deltaBalanceA = DesynSafeMath.bmul(currentBalanceA, DesynSafeMath.bdiv(deltaWeight, currentWeightA));

        // uint currentBalanceB = bPool.getBalance(tokenB);

        // uint deltaWeight = DesynSafeMath.bsub(newWeight, currentWeightA);

        // uint newWeightB = DesynSafeMath.bsub(currentWeightB, deltaWeight);
        // require(newWeightB >= 0, "ERR_INCORRECT_WEIGHT_B");
        bool soldout;
        if (deltaWeight == currentWeightA) {
            // reduct token A
            bPool.unbindPure(tokenA);
            soldout = true;
        }

        // Now with the tokens this contract can bind them to the pool it controls
        bPool.rebindSmart(tokenA, tokenB, deltaWeight, deltaBalanceA, soldout, minAmountOut);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
        }
    }

    function createPoolInternalHandle(IBPool bPool, uint initialSupply) external view {
        require(initialSupply >= DesynConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= DesynConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");
        require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        require(DesynConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");
    }

    function createPoolHandle(
        uint collectPeriod,
        uint upperCap,
        uint initialSupply
    ) external pure {
        require(collectPeriod <= DesynConstants.MAX_COLLECT_PERIOD, "ERR_EXCEEDS_FUND_RAISING_PERIOD");
        require(upperCap >= initialSupply, "ERR_CAP_BIGGER_THAN_INITSUPPLY");
    }

    function exitPoolHandle(
        uint _endEtfAmount,
        uint _endFundAmount,
        uint _beginEtfAmount,
        uint _beginFundAmount,
        uint poolAmountIn,
        uint totalEnd
    )
        external
        pure
        returns (
            uint endEtfAmount,
            uint endFundAmount,
            uint profitRate
        )
    {
        endEtfAmount = DesynSafeMath.badd(_endEtfAmount, poolAmountIn);
        endFundAmount = DesynSafeMath.badd(_endFundAmount, totalEnd);
        uint amount1 = DesynSafeMath.bdiv(endFundAmount, endEtfAmount);
        uint amount2 = DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount);
        if (amount1 > amount2) {
            profitRate = DesynSafeMath.bdiv(
                DesynSafeMath.bmul(DesynSafeMath.bsub(DesynSafeMath.bdiv(endFundAmount, endEtfAmount), DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount)), poolAmountIn),
                totalEnd
            );
        }
    }

    function exitPoolHandleA(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint _tokenAmountOut,
        uint redeemFee,
        uint profitRate,
        uint perfermanceFee
    )
        external
        returns (
            uint redeemAndPerformanceFeeReceived,
            uint finalAmountOut,
            uint redeemFeeReceived
        )
    {
        // redeem fee
        redeemFeeReceived = DesynSafeMath.bmul(_tokenAmountOut, redeemFee);

        // performance fee
        uint performanceFeeReceived = DesynSafeMath.bmul(DesynSafeMath.bmul(_tokenAmountOut, profitRate), perfermanceFee);
        
        // redeem fee and performance fee
        redeemAndPerformanceFeeReceived = DesynSafeMath.badd(performanceFeeReceived, redeemFeeReceived);

        // final amount the user got
        finalAmountOut = DesynSafeMath.bsub(_tokenAmountOut, redeemAndPerformanceFeeReceived);

        _pushUnderlying(bPool, poolToken, msg.sender, finalAmountOut);

        if (redeemFee != 0 || (profitRate > 0 && perfermanceFee != 0)) {
            _pushUnderlying(bPool, poolToken, address(this), redeemAndPerformanceFeeReceived);
            IERC20(poolToken).safeApprove(self.vaultAddress(), redeemAndPerformanceFeeReceived);
        }
    }

    function exitPoolHandleB(
        IConfigurableRightsPool self,
        bool bools,
        bool isCompletedCollect,
        uint closureEndTime,
        uint collectEndTime,
        uint _etfAmount,
        uint _fundAmount,
        uint poolAmountIn
    ) external view returns (uint etfAmount, uint fundAmount, uint actualPoolAmountIn) {
        actualPoolAmountIn = poolAmountIn;
        if (bools) {
            bool isCloseEtfCollectEndWithFailure = isCompletedCollect == false && block.timestamp >= collectEndTime;
            bool isCloseEtfClosureEnd = block.timestamp >= closureEndTime;
            require(isCloseEtfCollectEndWithFailure || isCloseEtfClosureEnd, "ERR_CLOSURE_TIME_NOT_ARRIVED!");

            actualPoolAmountIn = self.balanceOf(msg.sender);
        }
        fundAmount = _fundAmount;
        etfAmount = _etfAmount;
    }

    function joinPoolHandle(
        bool canWhitelistLPs,
        bool isList,
        bool bools,
        uint collectEndTime
    ) external view {
        require(!canWhitelistLPs || isList, "ERR_NOT_ON_WHITELIST");

        if (bools) {
            require(block.timestamp <= collectEndTime, "ERR_COLLECT_PERIOD_FINISHED!");
        }
    }

    function rebalanceHandle(
        IBPool bPool,
        bool bools,
        uint collectEndTime,
        uint closureEndTime,
        bool canChangeWeights,
        address tokenA,
        address tokenB
    ) external {
        require(bPool.isBound(tokenA), "ERR_TOKEN_NOT_BOUND");
        if (bools) {
            require(block.timestamp > collectEndTime && block.timestamp < closureEndTime, "ERR_NOT_REBALANCE_PERIOD");
        }

        if (!bPool.isBound(tokenB)) {
            bool returnValue = IERC20(tokenB).safeApprove(address(bPool), DesynConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");
        }

        require(canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
        require(tokenA != tokenB, "ERR_TOKENS_SAME");
    }

    /**
     * @notice Join a pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    ) external view returns (uint[] memory actualAmountsIn) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = DesynSafeMath.bdiv(poolAmountOut, DesynSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint tokenAmountIn = DesynSafeMath.bmul(ratio, DesynSafeMath.badd(bal, 1));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    ) external view returns (uint[] memory actualAmountsOut) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        uint ratio = DesynSafeMath.bdiv(poolAmountIn, DesynSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = DesynSafeMath.bmul(ratio, DesynSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    // Internal functions
    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }

    function handleTransferInTokens(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint actualAmountIn,
        uint _actualIssueFee
    ) external returns (uint issueFeeReceived) {
        issueFeeReceived = DesynSafeMath.bmul(actualAmountIn, _actualIssueFee);
        uint amount = DesynSafeMath.bsub(actualAmountIn, issueFeeReceived);

        _pullUnderlying(bPool, poolToken, msg.sender, amount);

        if (_actualIssueFee != 0) {
            bool xfer = IERC20(poolToken).transferFrom(msg.sender, address(this), issueFeeReceived);
            require(xfer, "ERR_ERC20_FALSE");

            IERC20(poolToken).safeApprove(self.vaultAddress(), issueFeeReceived);
        }
    }

    function handleClaim(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint managerFee,
        uint time
    ) external returns (uint[] memory tokensAmount) {
        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenBalance = bPool.getBalance(t);
            uint tokenAmountOut = DesynSafeMath.bmul(tokenBalance, (managerFee * time) / 12);
            _pushUnderlying(bPool, t, msg.sender, tokenAmountOut);

            IERC20(t).safeApprove(self.vaultAddress(), tokenAmountOut);
            tokensAmount[i] = tokenAmountOut;
        }
    }

    function handleCollectionCompleted(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint issueFee
    ) external {
        if (issueFee != 0) {
            uint[] memory tokensAmount = new uint[](poolTokens.length);

            for (uint i = 0; i < poolTokens.length; i++) {
                address t = poolTokens[i];
                uint currentAmount = bPool.getBalance(t);
                uint currentAmountFee = DesynSafeMath.bmul(currentAmount, issueFee);

                _pushUnderlying(bPool, t, address(this), currentAmountFee);
                tokensAmount[i] = currentAmountFee;
                IERC20(t).safeApprove(self.vaultAddress(), currentAmountFee);
            }

            IVault(self.vaultAddress()).depositIssueRedeemPToken(poolTokens, tokensAmount, tokensAmount, false);
        }
    }

    function WhitelistHandle(
        bool bool1,
        bool bool2,
        address adr
    ) external pure {
        require(bool1, "ERR_CANNOT_WHITELIST_LPS");
        require(bool2, "ERR_LP_NOT_WHITELISTED");
        require(adr != address(0), "ERR_INVALID_ADDRESS");
    }

    function _pullUnderlying(
        IBPool bPool,
        address erc20,
        address from,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, DesynSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    function _pushUnderlying(
        IBPool bPool,
        address erc20,
        address to,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, DesynSafeMath.bsub(tokenBalance, amount), tokenWeight);

        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

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
contract DesynOwnable {
    // State variables

    address private _owner;
    mapping(address => bool) public adminList;
    address[] public owners;
    uint[] public ownerPercentage;
    uint public allOwnerPercentage;
    bool private initialized;
    // Event declarations

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed newAdmin, uint indexed amount);
    event RemoveAdmin(address indexed oldAdmin, uint indexed amount);

    // Modifiers

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    modifier onlyAdmin() {
        require(adminList[msg.sender] || msg.sender == _owner, "onlyAdmin");
        _;
    }

    // Function declarations

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
    }

    function initHandle(address[] memory _owners, uint[] memory _ownerPercentage) external onlyOwner {
        require(_owners.length == _ownerPercentage.length, "ownerP");
        require(!initialized, "initialized!");
        for (uint i = 0; i < _owners.length; i++) {
            allOwnerPercentage += _ownerPercentage[i];
            adminList[_owners[i]] = true;
        }
        owners = _owners;
        ownerPercentage = _ownerPercentage;

        initialized = true;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     * @dev external for gas optimization
     * @param newOwner - address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     * @dev external for gas optimization
     * @param newOwner - address of new owner
     */
    function setAddAdminList(address newOwner, uint _ownerPercentage) external onlyOwner {
        require(!adminList[newOwner], "Address is Owner");

        adminList[newOwner] = true;
        owners.push(newOwner);
        ownerPercentage.push(_ownerPercentage);
        allOwnerPercentage += _ownerPercentage;
        emit AddAdmin(newOwner, _ownerPercentage);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner) external onlyOwner {
        adminList[owner] = false;
        uint amount = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                amount = ownerPercentage[i];
                ownerPercentage[i] = ownerPercentage[ownerPercentage.length - 1];
                break;
            }
        }
        owners.pop();
        ownerPercentage.pop();
        allOwnerPercentage -= amount;
        emit RemoveAdmin(owner, amount);
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwnerPercentage() public view returns (uint[] memory) {
        return ownerPercentage;
    }

    /**
     * @notice Returns the address of the current owner
     * @dev external for gas optimization
     * @return address - of the owner (AKA controller)
     */
    function getController() external view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../libraries/SmartPoolManager.sol";

interface IBPool {
    function rebind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function rebindSmart(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint deltaBalance,
        bool isSoldout,
        uint minAmountOut
    ) external;

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external returns (bytes memory _returnValue);

    function bind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function unbind(address token) external;

    function unbindPure(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint);

    function totalSupply() external view returns (uint);

    function getSwapFee() external view returns (uint);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function EXIT_FEE() external view returns (uint);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function setController(address owner) external;
}

interface IBFactory {
    function newLiquidityPool() external returns (IBPool);

    function setBLabs(address b) external;

    function collect(IBPool pool) external;

    function isBPool(address b) external view returns (bool);

    function getBLabs() external view returns (address);

    function getSwapRouter() external view returns (address);

    function getVault() external view returns (address);

    function getUserVault() external view returns (address);

    function getVaultAddress() external view returns (address);

    function getOracleAddress() external view returns (address);

    function getManagerOwner() external view returns (address);

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool);

    function isTokenWhitelistedForVerify(address token) external view returns (bool);

    function getModuleStatus(address etf, address module) external view returns (bool);

    function isPaused() external view returns (bool);
}

interface IVault {
    function depositManagerToken(address[] calldata poolTokens, uint[] calldata tokensAmount) external;

    function depositIssueRedeemPToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountP,
        bool isPerfermance
    ) external;

    function managerClaim(address pool) external;

    function getManagerClaimBool(address pool) external view returns (bool);
}

interface IUserVault {
    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface Oracles {
    function getPrice(address tokenAddress) external returns (uint price);

    function getAllPrice(address[] calldata poolTokens, uint[] calldata tokensAmount) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "./DesynConstants.sol";

/**
 * @author Desyn Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library DesynSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint c1 = c0 + (DesynConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / DesynConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0) {
            return 0;
        }

        uint c0 = dividend * DesynConstants.BONE;
        require(c0 / dividend == DesynConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

// Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
// Removing circularity allows flattener tools to work, which enables Etherscan verification
interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint amount) external;

    function pushPoolShareFromLib(address to, uint amount) external;

    function pullPoolShareFromLib(address from, uint amount) external;

    function burnPoolShareFromLib(uint amount) external;

    function balanceOf(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

    function getController() external view returns (address);

    function vaultAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "../interfaces/IERC20.sol";

// Libraries

/**
 * @author PieDAO (ported to Desyn Labs)
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice handle approvals of tokens that require approving from a base of 0
     * @param token - the token we're approving
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint amount
    ) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @author Desyn Labs
 * @title Put all the constants in one place
 */

library DesynConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = 0;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    //Fee Set
    uint public constant MANAGER_MIN_FEE = 0;
    uint public constant MANAGER_MAX_FEE = BONE / 10;
    uint public constant ISSUE_MIN_FEE = 0;
    uint public constant ISSUE_MAX_FEE = BONE / 10;
    uint public constant REDEEM_MIN_FEE = 0;
    uint public constant REDEEM_MAX_FEE = BONE / 10;
    uint public constant PERFERMANCE_MIN_FEE = 0;
    uint public constant PERFERMANCE_MAX_FEE = BONE / 2;
    // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint public constant MIN_ASSET_LIMIT = 1;
    uint public constant MAX_ASSET_LIMIT = 16;
    uint public constant MAX_UINT = uint(-1);
    uint public constant MAX_COLLECT_PERIOD = 60 days;
}