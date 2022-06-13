/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// File: contracts/library/ArrayLibrary.sol



pragma solidity ^0.8.7;

library ArrayLibrary {
    function removeAt(uint256[] storage self, uint256 index) public {
        self[index] = self[self.length - 1];
        self.pop();
    }

    function removeAt(address[] storage self, uint256 index) public {
        self[index] = self[self.length - 1];
        self.pop();
    }

    function findIndex(uint256[] memory self, uint256 value)
        public
        pure
        returns (uint256)
    {
        uint256 length = self.length;
        uint256 i;
        for (i = 0; i < length; ++i) {
            if (self[i] == value) {
                return i;
            }
        }
        return length;
    }

    function findIndex(address[] memory self, address value)
        public
        pure
        returns (uint256)
    {
        uint256 length = self.length;
        uint256 i;
        for (i = 0; i < length; ++i) {
            if (self[i] == value) {
                return i;
            }
        }
        return length;
    }

    function findMaxIndex(uint256[] memory self) public pure returns (uint256) {
        uint256 length = self.length;
        require(length > 0, "Empty Array");
        uint256 i;
        uint256 maxIdx = 0;
        for (i = 1; i < length; ++i) {
            if (self[i] > self[maxIdx]) {
                maxIdx = i;
            }
        }
        return maxIdx;
    }
}

// File: contracts/interface/IMockService.sol



pragma solidity ^0.8.0;

interface IMockService {
    function getEthPrice() external view returns (uint256);

    function getABlockPrice() external view returns (uint256);
}

// File: contracts/library/VerifySignature.sol


pragma solidity ^0.8;

contract VerifySignature {
    
    
    // use this function to get the hash of any string
    function getHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
    
    
    // take the keccak256 hashed message from the getHash function above and input into this function
    // this function prefixes the hash above with \x19Ethereum signed message:\n32 + hash
    // and produces a new hash signature
    function getEthSignedHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    
    // input the getEthSignedHash results and the signature hash results
    // the output of this function will be the account number that signed the original message
    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }


    // input the raw results and the signature hash results
    // the input is the result of keccak256
    // the output of this function will be the account number that signed the original message
    function verify_raw(bytes32 message, bytes memory _signature) public pure returns (address) {
        
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        
        return ecrecover(getEthSignedHash(message), v, r, s);
    }

    // input the raw results and the signature hash results
    // the input is the result of keccak256
    // the output of this function will be the account number that signed the original message
    function verify_raw_withinfo(bytes32 message, bytes memory _signature, uint256 nonce, string memory pro_id, string memory api_key, uint256 remained) public pure returns (address) {
        require(message == keccak256(abi.encodePacked(nonce, pro_id, api_key, remained)), "info mismatch");
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
        
        return ecrecover(getEthSignedHash(message), v, r, s);
    }

    function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
   }
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/interface/IDatabase.sol



pragma solidity ^0.8.7;



interface IDatabase {
    struct Project {
        string projectId;
        string apiKey;
        uint256 paidAmount;
        uint256 paidType;
        uint256 tierType;
        bool isActive;
        uint256 createdTime;
        uint256 paidTime;
    }

    //////////////////////////////////////////////////////
    /////////      MAIN FUNCTIONS      ///////////
    //////////////////////////////////////////////////////
    function createProject(string memory proId, string memory apiKey) external;

    function removeProject(string memory proId) external;

    function activateProject(
        string memory proId,
        uint256 paidType,
        uint256 tierType,
        uint256 amount
    ) external;

    //////////////////////////////////////////////////////
    ////////////           Setting            ////////////
    //////////////////////////////////////////////////////

    function setChannel(address channel_) external;

    //////////////////////////////////////////////////////
    /////////            READ FUNCTIONS        ///////////
    //////////////////////////////////////////////////////
    function getProject(string memory proId)
        external
        view
        returns (Project memory);

    function isProjectActive(string memory proId) external view returns (bool);

    function isProjectExist(string memory proId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/library/MockPaymentChannelBase.sol


pragma solidity ^0.8.7;






abstract contract MockPaymentChannelBase is VerifySignature, Ownable {
    IERC20 internal aBlockToken;
    IERC20 internal aaBlockToken;
    address internal signer;
    IDatabase internal db;
    IMockService internal service;

    uint256 internal nonce;
    mapping(string => address) public _users;
    mapping(string => uint256) public _balances;
    mapping(string => uint256) public _payTypes;

    event PAID(uint256 payType, string proId, uint256 amount);

    //////////////////////////////////////////////////////
    /////////      Constructor & Modifier      ///////////
    //////////////////////////////////////////////////////
    constructor(
        address aBlockToken_,
        address aaBlockToken_,
        address signer_,
        address db_,
        address service_
    ) {
        aBlockToken = IERC20(aBlockToken_);
        aaBlockToken = IERC20(aaBlockToken_);
        signer = signer_;
        db = IDatabase(db_);
        service = IMockService(service_);
    }
    //////////////////////////////////////////////////////
    /////////          MAIN FUNCTIONS          ///////////
    //////////////////////////////////////////////////////
    function payWithABlock(string memory proId, uint256 amount) public virtual {
        aBlockToken.transferFrom(msg.sender, address(this), amount);
        _users[proId] = msg.sender;
        _balances[proId] += amount;
        _payTypes[proId] = 1;
        emit PAID(1, proId, amount);
    }

    function payWithAABlock(string memory proId, uint256 amount)
        public
        virtual
    {
        aaBlockToken.transferFrom(msg.sender, address(this), amount);
        _users[proId] = msg.sender;
        _balances[proId] += amount;
        _payTypes[proId] = 2;
        emit PAID(1, proId, amount);
    }

    function payWithEth(string memory proId, uint256 amount)
        public
        payable
        virtual
    {
        require(msg.value >= amount, "fund_mismatch");
        _users[proId] = msg.sender;
        _balances[proId] += amount;
        _payTypes[proId] = 0;
        emit PAID(0, proId, amount);
    }

    function refund_by_signer(string memory proId, uint256 amount)
        public
        virtual
    {
        require(msg.sender == signer, "Not A Signer");
        _refund(proId, _users[proId], amount);
    }

    function refund_by_user(
        bytes32 message,
        bytes memory signature,
        string memory proId,
        string memory api_key,
        uint256 remained
    ) public virtual{
        require(
            verify_raw_withinfo(
                message,
                signature,
                nonce,
                proId,
                api_key,
                remained
            ) == signer,
            "invalid info"
        );
        _refund(proId, msg.sender, remained);
        nonce++;
    }

    //////////////////////////////////////////////////////
    ////////////           Setting            ////////////
    //////////////////////////////////////////////////////

    function setSigner(address signer_) public onlyOwner {
        signer = signer_;
    }

    function getNonce() public view returns (uint256) {
        require(msg.sender == signer, "Not A Signer");
        return nonce;
    }

    //////////////////////////////////////////////////////
    ////////////      INTERNAL FUNCTIONS      ////////////
    //////////////////////////////////////////////////////

    function _refund(
        string memory proId,
        address to,
        uint256 amount
    ) internal {
        uint256 payType = _payTypes[proId];
        if (payType == 0) {
            payable(to).transfer(amount);
        } else if (payType == 1) {
            aBlockToken.transfer(to, amount);
        } else if (payType == 2) {
            aBlockToken.transfer(to, amount);
        }
        _balances[proId] -= amount;
    }
}

// File: contracts/MockPaymentChannel.sol


pragma solidity ^0.8.7;




contract MockPaymentChannel is MockPaymentChannelBase {
    //////////////////////////////////////////////////////
    /////////    Constructor & Modifier    ///////////
    //////////////////////////////////////////////////////
    address private myOwner;

    constructor(
        address aBlockToken_,
        address aaBlockToken_,
        address signer_,
        address db_,
        address service_
    )
        MockPaymentChannelBase(
            aBlockToken_,
            aaBlockToken_,
            signer_,
            db_,
            service_
        )
    {
        myOwner = msg.sender;
    }

    //////////////////////////////////////////////////////
    /////////      MAIN FUNCTIONS      ///////////
    //////////////////////////////////////////////////////

    function createChannel(string memory proId, string memory apiKey) external {
        db.createProject(proId, apiKey);
    }

    function payWithABlock(string memory proId, uint256 amount)
        public
        override
    {
        uint256 price = service.getABlockPrice();
        uint256 tier1 = (35 * 80) / price;
        uint256 tier2 = (200 * 80) / price;

        require(amount >= tier1, "Insufficient aBlock");
        if (amount < tier2) {
            super.payWithABlock(proId, tier1);
            db.activateProject(proId, 1, 1, tier1);
        } else {
            super.payWithABlock(proId, tier2);
            db.activateProject(proId, 1, 2, tier2);
        }
    }

    function payWithAABlock(string memory proId, uint256 amount)
        public
        override
    {
        super.payWithAABlock(proId, amount);
        db.activateProject(proId, 2, 1, amount);
    }

    function payWithEth(string memory proId, uint256 amount)
        public
        payable
        override
    {
        require(msg.value >= amount, "insufficient eth");
        uint256 price = service.getEthPrice();
        uint256 tier1 = (35 * 1000000 ether) / price;
        uint256 tier2 = (200 * 1000000 ether) / price;
        require(amount >= tier1, "Insufficient eth");
        if (amount < tier2) {
            super.payWithEth(proId, tier1);
            db.activateProject(proId, 0, 1, tier1);
            if (amount > (tier1 + 5 * 10**15)) {
                payable(msg.sender).transfer(amount - tier1 - 5 * 10**15);
            }
        } else {
            super.payWithEth(proId, tier2);
            db.activateProject(proId, 0, 2, tier2);
            if (amount > (tier2 + 5 * 10**15)) {
                payable(msg.sender).transfer(amount - tier2 - 5 * 10**15);
            }
        }
        // payable(msg.sender).transfer(5 * 10**15);
    }

    function refund_by_signer(string memory proId, uint256 amount)
        public
        override
    {
        super.refund_by_signer(proId, amount);
        db.removeProject(proId);
    }

    function refund_by_user(
        bytes32 message,
        bytes memory signature,
        string memory proId,
        string memory api_key,
        uint256 remained
    ) public override{
        super.refund_by_user(message, signature, proId, api_key, remained);
        db.removeProject(proId);
    }
}