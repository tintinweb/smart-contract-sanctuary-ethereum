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

pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";
import "../utils/DesynOwnable.sol";
// Contracts
pragma experimental ABIEncoderV2;

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);
}

interface IToken {
    function decimals() external view returns (uint);
}

interface IUserVault {
    function depositToken(
        address pool,
        uint types,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface IDesynOwnable {
    function getOwners() external view returns (address[] memory);

    function getOwnerPercentage() external view returns (uint[] memory);

    function allOwnerPercentage() external view returns (uint);
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract Vault is DesynOwnable {
    using SafeMath for uint;
    using Address for address;

    ICRPFactory crpFactory;
    address public userVault;

    event ManagerRatio(address indexed caller, uint indexed amount);
    event LOGUserVaultAdr(address indexed manager, address indexed caller);
    event IssueRatio(address indexed caller, uint indexed amount);
    event RedeemRatio(address indexed caller, uint indexed amount);

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
    }

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) public poolsStatus;

    //history record
    mapping(address => uint) public record_number;
    mapping(address => mapping(uint => ClaimRecordInfo)) public record_List;

    //pool=>manager
    mapping(address => address) public pool_manager;

    // default ratio config
    uint public RATIO_TOTAL = 1000;
    uint public RATIO_MANAGER = 800;
    uint public RATIO_ISSUE = 800;
    uint public RATIO_REDEEM = 800;
    uint public RATIO_PERFERMANCE = 800;

    receive() external payable {}

    function depositManagerToken(address[] calldata poolTokens, uint[] calldata tokensAmount) public {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(poolTokens.length == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        if (pool_manager[pool] == address(0)) {
            pool_manager[pool] = ICRPPool(pool).getController();
        }

        PoolTokens storage tokens = poolsTokens[pool];

        (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) = communaldepositToken(
            poolTokens,
            tokensAmount,
            pool,
            tokens.tokenList,
            tokens.managerAmount
        );
        tokens.tokenList = new_pool_tokenList;
        tokens.managerAmount = new_pool_tokenAmount;
        poolsStatus[pool].couldManagerClaim = true;
        if (isClosePool(pool)) {
            try this.managerClaim(pool) {} catch {}
        }
    }

    function depositIssueRedeemPToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountIR,
        bool isPerfermance
    ) public {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(poolTokens.length == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        if (pool_manager[pool] == address(0)) {
            pool_manager[pool] = ICRPPool(pool).getController();
        }
        PoolTokens storage tokens = poolsTokens[pool];

        if (!isPerfermance) {
            (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) = communaldepositToken(
                poolTokens,
                tokensAmount,
                pool,
                tokens.issueTokens,
                tokens.issueAmount
            );
            tokens.issueTokens = new_pool_tokenList;
            tokens.issueAmount = new_pool_tokenAmount;
        } 
        if (isPerfermance) {
            (
                address[] memory new_pool_tokenList,
                uint[] memory new_pool_tokenAmount,
                address[] memory new_pool_tokenListP,
                uint[] memory new_pool_tokenAmountP
            ) = communaldepositTokenNew(poolTokens, tokensAmount, tokensAmountIR, pool);
            tokens.redeemTokens = new_pool_tokenList;
            tokens.redeemAmount = new_pool_tokenAmount;
            tokens.perfermanceTokens = new_pool_tokenListP;
            tokens.perfermanceAmount = new_pool_tokenAmountP;
        }

        poolsStatus[pool].couldManagerClaim = true;
        if (isClosePool(pool)) {
            try this.managerClaim(pool) {} catch {}
        }
    }

    function communaldepositToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        address poolAdr,
        address[] memory _pool_tokenList,
        uint[] memory _pool_tokenAmount
    ) internal returns (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) {
        //old
        //new
        new_pool_tokenList = new address[](poolTokens.length);
        new_pool_tokenAmount = new uint[](poolTokens.length);
        if ((_pool_tokenList.length == _pool_tokenAmount.length && _pool_tokenList.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < poolTokens.length; i++) {
                address t = poolTokens[i];
                uint tokenBalance = tokensAmount[i];
                IERC20(t).transferFrom(msg.sender, address(this), tokenBalance);
                new_pool_tokenList[i] = poolTokens[i];
                new_pool_tokenAmount[i] = tokensAmount[i];
            }
        } else {
            for (uint k = 0; k < poolTokens.length; k++) {
                if (_pool_tokenList[k] == poolTokens[k]) {
                    address t = poolTokens[k];
                    uint tokenBalance = tokensAmount[k];
                    IERC20(t).transferFrom(msg.sender, address(this), tokenBalance);
                    new_pool_tokenList[k] = poolTokens[k];
                    new_pool_tokenAmount[k] = _pool_tokenAmount[k].add(tokenBalance);
                }
            }
        }
        return (new_pool_tokenList, new_pool_tokenAmount);
    }

    function communaldepositTokenNew(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountIR,
        address poolAdr
    )
        internal
        returns (
            address[] memory new_pool_tokenList,
            uint[] memory new_pool_tokenAmount,
            address[] memory new_pool_tokenListP,
            uint[] memory new_pool_tokenAmountP
        )
    {
        //old
        //new
        new_pool_tokenList = new address[](poolTokens.length);
        new_pool_tokenAmount = new uint[](poolTokens.length);
        new_pool_tokenListP = new address[](poolTokens.length);
        new_pool_tokenAmountP = new uint[](poolTokens.length);

        PoolTokens storage tokens = poolsTokens[poolAdr];

        //issue_redeem
        if ((tokens.redeemTokens.length == tokens.redeemAmount.length && tokens.redeemTokens.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < poolTokens.length; i++) {
                uint tokenBalance = tokensAmount[i];
                IERC20(poolTokens[i]).transferFrom(msg.sender, address(this), tokenBalance);
                new_pool_tokenList[i] = poolTokens[i];
                new_pool_tokenAmount[i] = tokensAmountIR[i];
            }
        } else {
            for (uint k = 0; k < poolTokens.length; k++) {
                if (tokens.redeemTokens[k] == poolTokens[k]) {
                    uint tokenBalance = tokensAmount[k];
                    IERC20(poolTokens[k]).transferFrom(msg.sender, address(this), tokenBalance);
                    new_pool_tokenList[k] = poolTokens[k];
                    new_pool_tokenAmount[k] = tokens.perfermanceAmount[k].add(tokensAmountIR[k]);
                }
            }
        }
        //perfermance
        if ((tokens.perfermanceTokens.length == tokens.perfermanceAmount.length && tokens.perfermanceTokens.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < poolTokens.length; i++) {
                new_pool_tokenListP[i] = poolTokens[i];
                new_pool_tokenAmountP[i] = tokensAmount[i].sub(tokensAmountIR[i]);
            }
        } else {
            for (uint k = 0; k < poolTokens.length; k++) {
                new_pool_tokenListP[k] = poolTokens[k];
                new_pool_tokenAmountP[k] = tokens.perfermanceAmount[k].add(tokensAmount[k].sub(tokensAmountIR[k]));
            }
        }

        return (new_pool_tokenList, new_pool_tokenAmount, new_pool_tokenListP, new_pool_tokenAmountP);
    }

    function poolManagerTokenList(address pool) public view returns (address[] memory tokens) {
        return poolsTokens[pool].tokenList;
    }

    function poolManagerTokenAmount(address pool) public view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].managerAmount;
    }

    function poolIssueTokenList(address pool) public view returns (address[] memory tokens) {
        return poolsTokens[pool].issueTokens;
    }

    function poolRedeemTokenList(address pool) public view returns (address[] memory tokens) {
        return poolsTokens[pool].redeemTokens;
    }

    function poolIssueTokenAmount(address pool) public view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].issueAmount;
    }

    function poolRedeemTokenAmount(address pool) public view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].redeemAmount;
    }

    function poolPerfermanceTokenList(address pool) public view returns (address[] memory tokens) {
        return poolsTokens[pool].perfermanceTokens;
    }

    function poolPerfermanceTokenAmount(address pool) public view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].perfermanceAmount;
    }

    function getManagerClaimBool(address pool) public view returns (bool bools) {
        bools = poolsStatus[pool].couldManagerClaim;
    }

    function setBlackList(address pool, bool bools) public onlyOwner {
        poolsStatus[pool].isBlackList = bools;
    }

    function setUserVaultAdr(address adr) public onlyOwner {
        require(adr != address(0), "ERR_INVALID_USERVAULT_ADDRESS");
        userVault = adr;
        emit LOGUserVaultAdr(adr, msg.sender);
    }

    function setCrpFactory(address adr) public onlyOwner {
        crpFactory = ICRPFactory(adr);
    }

    function adminClaimToken(
        address token,
        address user,
        uint amount
    ) public onlyOwner {
        IERC20(token).transfer(user, amount);
    }

    function getBNB() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setManagerRatio(uint amount) public onlyOwner {
        require(amount <= RATIO_TOTAL, "Maximum limit exceeded");
        RATIO_MANAGER = amount;
        emit ManagerRatio(msg.sender, amount);
    }

    function setIssueRatio(uint amount) public onlyOwner {
        require(amount <= RATIO_TOTAL, "Maximum limit exceeded");
        RATIO_ISSUE = amount;
        emit IssueRatio(msg.sender, amount);
    }

    function setRedeemRatio(uint amount) public onlyOwner {
        require(amount <= RATIO_TOTAL, "Maximum limit exceeded");
        RATIO_REDEEM = amount;
        emit RedeemRatio(msg.sender, amount);
    }

    function setPerfermanceRatio(uint amount) public onlyOwner {
        RATIO_PERFERMANCE = amount;
    }

    function managerClaim(address pool) public {
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        address manager_address = ICRPPool(pool).getController();

        PoolTokens memory tokens = poolsTokens[pool];
        PoolStatus storage status = poolsStatus[pool];

        address[] memory _pool_manager_tokenList = tokens.tokenList.length != 0
            ? tokens.tokenList
            : (tokens.issueTokens.length != 0 ? tokens.issueTokens : (tokens.redeemTokens.length != 0 ? tokens.redeemTokens : tokens.perfermanceTokens));
        require(!status.isBlackList, "ERR_POOL_IS_BLACKLIST");
        require(pool_manager[pool] == manager_address, "ERR_IS_NOT_MANAGER");
        require(_pool_manager_tokenList.length > 0, "ERR_NOT_MANGER_FEE");
        require(status.couldManagerClaim, "ERR_MANAGER_COULD_NOT_CLAIM");
        status.couldManagerClaim = false;
        //record
        ClaimRecordInfo storage recordInfo = record_List[pool][record_number[pool].add(1)];
        delete recordInfo.time;
        delete recordInfo.tokens;
        recordInfo.time = block.timestamp;
        uint[] memory managerTokenAmount = new uint[](_pool_manager_tokenList.length);
        uint[] memory issueTokenAmount = new uint[](_pool_manager_tokenList.length);
        uint[] memory redeemTokenAmount = new uint[](_pool_manager_tokenList.length);
        uint[] memory perfermanceTokenAmount = new uint[](_pool_manager_tokenList.length);
        for (uint i = 0; i < _pool_manager_tokenList.length; i++) {
            uint balance;
            ClaimTokenInfo memory tokenInfo;
            (balance, managerTokenAmount[i], issueTokenAmount[i], redeemTokenAmount[i], perfermanceTokenAmount[i]) = computeBalance(i, pool);
            address t = _pool_manager_tokenList[i];
            tokenInfo.token = t;
            tokenInfo.amount = balance;
            tokenInfo.decimals = IToken(t).decimals();
            recordInfo.tokens.push(tokenInfo);
            transferHandle(pool, manager_address, t, balance);
        }
        if (isClosePool(pool)) {
            recordUserVault(pool, _pool_manager_tokenList, managerTokenAmount, issueTokenAmount, redeemTokenAmount, perfermanceTokenAmount);
        }

        record_number[pool] = record_number[pool].add(1);
        record_List[pool][record_number[pool]] = recordInfo;
        clearPool(pool);
    }

    function recordUserVault(
        address pool,
        address[] memory tokenList,
        uint[] memory managerTokenAmount,
        uint[] memory issueTokenAmount,
        uint[] memory redeemTokenAmount,
        uint[] memory perfermanceTokenAmount
    ) internal {
        PoolTokens memory tokens = poolsTokens[pool];

        if (tokens.managerAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 0, tokenList, managerTokenAmount);
        }
        if (tokens.issueAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 1, tokenList, issueTokenAmount);
        }
        if (tokens.redeemAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 2, tokenList, redeemTokenAmount);
        }
        if (tokens.perfermanceAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 3, tokenList, perfermanceTokenAmount);
        }
    }

    function transferHandle(
        address pool,
        address manager_address,
        address t,
        uint balance
    ) internal {
        bool isCloseETF = isClosePool(pool);
        bool isOpenETF = !isCloseETF;
        bool isContractManager = manager_address.isContract();

        if(isCloseETF){
            IERC20(t).transfer(userVault, balance);
        }

        if(isOpenETF && isContractManager){
            address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
            uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
            uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

            for (uint k = 0; k < managerAddressList.length; k++) {
                IERC20(t).transfer(managerAddressList[k], balance.mul(ownerPercentage[k]).div(allOwnerPercentage));
            }
        }

        if(isOpenETF && !isContractManager){
            IERC20(t).transfer(manager_address, balance);
        }
    }

    function computeBalance(uint i, address pool)
        internal
        view
        returns (
            uint balance,
            uint balanceOne,
            uint balanceTwo,
            uint balanceThree,
            uint balanceFour
        )
    {
        PoolTokens memory tokens = poolsTokens[pool];

        //manager fee
        if (tokens.managerAmount.length != 0) {
            balanceOne = tokens.managerAmount[i].mul(RATIO_MANAGER).div(RATIO_TOTAL);
            balance = balance.add(balanceOne);
        }
        if (tokens.issueAmount.length != 0) {
            balanceTwo = tokens.issueAmount[i].mul(RATIO_ISSUE).div(RATIO_TOTAL);
            balance = balance.add(balanceTwo);
        }
        if (tokens.redeemAmount.length != 0) {
            balanceThree = tokens.redeemAmount[i].mul(RATIO_REDEEM).div(RATIO_TOTAL);
            balance = balance.add(balanceThree);
        }
        if (tokens.perfermanceAmount.length != 0) {
            balanceFour = tokens.perfermanceAmount[i].mul(RATIO_PERFERMANCE).div(RATIO_TOTAL);
            balance = balance.add(balanceFour);
        }
    }

    function isClosePool(address pool) public view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function clearPool(address pool) internal {
        delete poolsTokens[pool];
    }

    function managerClaimRecordList(address pool) public view returns (ClaimRecordInfo[] memory claimRecordInfos) {
        uint num = record_number[pool];
        ClaimRecordInfo[] memory records = new ClaimRecordInfo[](num);
        for (uint i = 1; i < num + 1; i++) {
            ClaimRecordInfo memory record;
            record = record_List[pool][i];
            records[i.sub(1)] = record;
        }
        return records;
    }

    function managerClaimList(address pool) public view returns (ClaimTokenInfo[] memory claimTokenInfos) {
        PoolTokens memory tokens = poolsTokens[pool];
        address[] memory _pool_manager_tokenList = tokens.tokenList.length != 0
            ? tokens.tokenList
            : (tokens.issueTokens.length != 0 ? tokens.issueTokens : (tokens.redeemTokens.length != 0 ? tokens.redeemTokens : tokens.perfermanceTokens));

        ClaimTokenInfo[] memory infos = new ClaimTokenInfo[](_pool_manager_tokenList.length);
        for (uint i = 0; i < _pool_manager_tokenList.length; i++) {
            {
                ClaimTokenInfo memory tokenInfo;
                tokenInfo.token = _pool_manager_tokenList[i];

                (uint balance,,,,) = computeBalance(i,pool);
                tokenInfo.amount = balance;
                tokenInfo.decimals = IToken(_pool_manager_tokenList[i]).decimals();
                
                infos[i] = tokenInfo;
            }
        }

        return infos;
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
        for (uint i = 0; i < _owners.length; i++) {
            allOwnerPercentage += _ownerPercentage[i];
            adminList[_owners[i]] = true;
        }
        owners = _owners;
        ownerPercentage = _ownerPercentage;
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