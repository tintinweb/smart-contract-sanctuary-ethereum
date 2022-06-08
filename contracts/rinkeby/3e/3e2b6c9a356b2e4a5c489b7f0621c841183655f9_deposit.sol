/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: 押金合约/deposit.sol


pragma solidity ^0.8.0;



contract deposit is Ownable{

    address private manager;

    struct turnover{
        address tokenAddr;// If the currency of the deposit is zero, the address is eth
        uint256 amount;// The amount of the deposit
        address from;// The source account of the deposit
        address to;
        bool isEffective;// Identifies whether the deposit has been created 
        bool isused;// Identifies whether the deposit is used 
    }

    mapping(string => turnover) private deploys;// A deposit uniquely identified by businessId

    mapping(address => mapping(address => uint256)) private balances;// Record the total deposit amount of an account in a certain currency

    event Payment(string businessId);// payment event, record the receipt of deposit transfer from an account

    event Withdraw(string[] businessIds);// withdraw event, record an account to withdraw a certain deposit

    event Expend(string[] businessIds);// Expend event, record the transfer of a certain deposit from the contract from the ownen account
    
    event Received(address tokenaddr,address payee,uint256 amount);// Received event, record the contract received ETH transfer but no function call

    event Manager(address manager);

    modifier onlyManager(){
	    require(msg.sender == manager, "Not the manager");
        _;
    }

    constructor(){
        manager = msg.sender;
    }

    function setManager(
        address _manager
    ) public onlyOwner {
        manager = _manager;
        emit Manager(_manager);
    }

    function getManager(
    ) public view returns (address) {
        return manager;
    }

    /**
     * exit Check if the deposit ID has already been created
     */
    function exit(string memory businessId) public view returns (bool){
        return deploys[businessId].isEffective;
    }

    /**
     * used Check if the deposit ID has been withdrawn
     */
    function used(string memory businessId) public view returns (bool){
        return deploys[businessId].isused;
    }

    function getDeposit(string memory businessId) public view returns (address tokenAddr, uint256 amount, address fromAddr, address toAddr){
        tokenAddr = deploys[businessId].tokenAddr;
        amount = deploys[businessId].amount;
        fromAddr = deploys[businessId].from; 
        toAddr = deploys[businessId].to;
    }
    
    /**
     * payment User calls to send deposit operation
     */
    function payment(
        address tokenAddr, 
        uint256 amount, 
        string calldata businessId,
        bytes calldata sig
    ) external payable {
        require(verifyPayment(tokenAddr, amount, businessId, sig),"illegal signature");
        if (tokenAddr == address(0)){//eth
            require(msg.value >= amount,"Not enough eth tokens");
            require(!exit(businessId),"BusinessId already exists");
            deploys[businessId] = turnover(tokenAddr, msg.value, msg.sender, address(0), true, false);
            balances[msg.sender][tokenAddr] += msg.value;
            emit Payment(businessId);
        }else{//erc20
            IERC20 token = IERC20(tokenAddr);
            uint256 _amount = token.allowance(msg.sender,address(this));
            if(amount > _amount || _amount == 0){
                revert("Not enough tokens approve");
            }else{
                bool success = token.transferFrom(msg.sender, address(this), amount);
                require(success,"ERC20 transferFrom fail");
                require(!exit(businessId),"BusinessId already exists");
                deploys[businessId] = turnover(tokenAddr, amount, msg.sender, address(0), true, false);
                balances[msg.sender][tokenAddr] += amount;
                emit Payment(businessId);
            }
        }
    }

    /**
     * helper The user calls to get the hash of the background account that needs to be signed
     */
    function helperPayment(
        address msgSender,
        address tokenAddr, 
        uint256 amount, 
        string calldata businessId
    )  public pure returns (bytes32) {
        bytes memory message = abi.encode(msgSender, tokenAddr, amount, businessId);
        bytes32 hash = keccak256(message);
        return hash;
    }

    /**
     * verify Verify that the user's order withdrawal is legal
     */
    function verifyPayment(
        address tokenAddr, 
        uint256 amount, 
        string calldata businessId,
        bytes  calldata _sig
    ) internal view returns (bool) {
        bytes memory message = abi.encode(msg.sender, tokenAddr, amount, businessId);
        bytes32 hash = keccak256(message);
        address _address = ecrecovery(hash,_sig);
        if(manager  == _address){
            return true;
        }else{
            return false;
        }
    }

    /**
     * helper The user calls to get the hash of the background account that needs to be signed
     */
    function helperWithdraw(
        address msgSender,
        string[] calldata businessIds
    )  public pure returns (bytes32) {
        bytes memory message = abi.encode(msgSender, businessIds);
        bytes32 hash = keccak256(message);
        return hash;
    }

    /**
     * verify Verify that the user's order withdrawal is legal
     */
    function verifyWithdraw(
        string[] calldata businessId,
        bytes  calldata _sig
    )  internal view returns (bool) {
        bytes memory message = abi.encode(msg.sender, businessId);
        bytes32 hash = keccak256(message);
        address _address = ecrecovery(hash, _sig);
        if(manager  == _address){
            return true;
        }else{
            return false;
        }
  }

    /**
     * _transferEth Transfer eth
     */
    function _transferEth(
        address _to, 
        uint256 _amount
    ) internal returns (bool){
        (bool _success, ) = _to.call{value: _amount}('');
        // require(success, "_transferEth: Eth transfer failed");
        return _success;
    }

    /**
     * _transferERC20 Make an erc20 transfer
     */
    function _transferERC20(
        address tokenAddr, 
        address _to, 
        uint256 _amount
    ) internal returns (bool){
        IERC20 token = IERC20(tokenAddr);
        bool _success = token.transfer(_to,_amount);
        // require(success, "_transferERC20: ERC20 token transfer failed");
        return _success;
    }

    /**
     * _withdraw The user withdraws the deposit for placing an order identified by the businessId
     */
    function _withdraw(
        string  memory _businessId,
        address _tokenAddr,
        uint256 _amount,
        address _fromAddr,
        address _toAddr
    ) internal returns (bool){
        if(!exit(_businessId) || used(_businessId)){
            return false;
        }

        deploys[_businessId].isused = true;
        deploys[_businessId].to = _toAddr;
        balances[_fromAddr][_tokenAddr] -= _amount;

        if(_tokenAddr == address(0)){//eth
            bool _success = _transferEth(_toAddr,_amount);
            if (!_success){
                return false;
            }
        }else{//erc20
            bool _success = _transferERC20(_tokenAddr, _toAddr,_amount);
            if (!_success){
                return false;
            }
        }
        return true;
    }

    /**
     * withdraw The user withdraws the deposit for placing an order identified by the businessId
     */
    function withdraw(
        string[]  calldata businessIds, 
        address[] calldata toAddrs,
        bytes  calldata sign
    ) external {
        uint256 len = businessIds.length;
        require(len == toAddrs.length,"LENGTH_MISMATCH");

        bool success = verifyWithdraw(businessIds, sign);
        require(success,"Illegal signature");
        
        string[] memory successBusinessIds = new string[](len);
        uint256 j = 0;
        
        for(uint256 i = 0; i < len; ++i){

            string memory _businessId = businessIds[i];
            if(!(deploys[_businessId].from == msg.sender)){
                continue;
            }

            address _tokenAddr = deploys[_businessId].tokenAddr;
            uint256 _amount = deploys[_businessId].amount;
            address _fromAddr = deploys[_businessId].from; 
            address _toAddr = toAddrs[i];

            bool _success = _withdraw(_businessId, _tokenAddr, _amount, _fromAddr, _toAddr);
                if (_success){
                    successBusinessIds[j++] = _businessId;
                }
            emit Withdraw(successBusinessIds);
        }
    }

    /**
     * queryUserBalance Query the amount of a certain token that the user has stored in the contract
     */
    function queryUserBalance(address tokenAddr, address userAddr) external view returns(uint256){
        return balances[userAddr][tokenAddr];
    }

    /**
     * expend The owner account withdraws the order deposit identified by the businessId
     */
    function expend(
        string[] calldata businessIds,
        address[] calldata toAddrs
    ) external onlyManager {
        uint256 len = businessIds.length;
        require(len == toAddrs.length,"LENGTH_MISMATCH");

        string[] memory successBusinessIds = new string[](len);
        uint256 j = 0;
           
        for(uint256 i = 0; i < len; ++i){

            string memory _businessId = businessIds[i];
            address _tokenAddr = deploys[_businessId].tokenAddr;
            uint256 _amount = deploys[_businessId].amount;
            address _fromAddr = deploys[_businessId].from; 
            address _toAddr = toAddrs[i];

            bool _success = _withdraw(_businessId, _tokenAddr, _amount, _fromAddr, _toAddr);
            if (_success){
                successBusinessIds[j++] = _businessId;
            }
        }
        emit Expend(successBusinessIds);
    }

    /**
     * Balance Query the balance of a certain token corresponding to the contract
     */
    function balanceofToken(address tokenAddr) public view returns (uint256) {
        if(tokenAddr == address(0)){
            return address(this).balance;
        }else{
            return  IERC20(tokenAddr).balanceOf(address(this));
        }
    }


    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory ret = new string(_ba.length + _bb.length + _bc.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bret[k++] = _bc[i];
        return string(ret);
    }

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

    function ecrecovery(
        bytes32 hash, 
        bytes memory sig
    ) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
         return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
        v += 27;
        }

        if (v != 27 && v != 28) {
        return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        // hash = sha3(prefix, hash);

        return ecrecover(hash, v, r, s);
  }

    // receive ETH
    receive() external payable {
        emit Received(address(0), msg.sender, msg.value);
    }
}