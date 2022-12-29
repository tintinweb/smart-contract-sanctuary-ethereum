/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Multisign-1.sol



pragma solidity ^0.8.17;


interface IERC20 
{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


}
contract MultiLayerMultiSign is Ownable {
    //mapping(address=>bool) public Layer1OPKeys;
    //mapping(address=>bool) public Layer2OPKeys;
    struct KeyList {
        address KeyAddr;
        bool    Flag;
    }
    struct TrxStr {
        address TargetAddress;
        uint256 TrxAmount;
        //bool FinishFlag;
    }

    TrxStr [] public TrxPool;
    KeyList[] public Layer1OPKeys;
    KeyList[] public Layer2OPKeys;

    address public ERCType;
    address public L2Signed;
    
    uint8 public TrxPoolStatus;
    uint8 public ApproveQty;
    uint8 public SignQty;
    
    bytes32 public TrxPoolHash;
    
    event TrxExecuted(address indexed _to,uint256 _amount);
    event TrxSetup(TrxStr[] _trxpool,bytes32 _trxhash);

function CheckKey(address _key ,KeyList[] memory _OPKey) private pure returns(bool) {
    for(uint8 i=0;i<_OPKey.length;i++){
        if(_key==_OPKey[i].KeyAddr&&_OPKey[i].Flag)
        return true;
    }
    return false;
}

function SetupTrxPool (address[] memory _Target, uint256[] memory _amnt) public
{
    uint256 PoolSummary;
    TrxStr memory _temp;
    require(_Target.length<=10 &&_Target.length==_amnt.length&& CheckKey(msg.sender,Layer1OPKeys)&&TrxPoolStatus<=1&&Layer2OPKeys.length>0,"Setup Transaction Pool Failed");
    //insert fail event

    delete TrxPool;
     for(uint8 i=0; i<_Target.length; i++){
            _temp.TargetAddress=_Target[i];
            _temp.TrxAmount=_amnt[i];
            TrxPool.push(_temp);
            PoolSummary+=_amnt[i];
        }
     if (PoolSummary>=100000*1000000 ){
          ApproveQty=2;
     } else {
          ApproveQty=1;
  }
    TrxPoolStatus=2;
    TrxPoolHash=keccak256(abi.encode(TrxPool));
    //insert Successful event
    emit TrxSetup(TrxPool,TrxPoolHash);
}

function ExecuteTrx() private {
    for(uint8 i=0;i<TrxPool.length;i++) {
        IERC20(ERCType).transfer(TrxPool[i].TargetAddress,TrxPool[i].TrxAmount);
        emit TrxExecuted(TrxPool[i].TargetAddress,TrxPool[i].TrxAmount);
    }
}

function ApproveStage(address[] memory _Target, uint256[] memory _amnt) public {
    bytes32 _Trxpoolhash;

    require(_Target.length<=10&&_Target.length==_amnt.length && CheckKey(msg.sender,Layer2OPKeys) &&TrxPoolStatus>1,"Approve Failed");
    //_Trxpoolhash=keccak256(abi.encode(_Trxpool));
    TrxStr[] memory _temp = new TrxStr[](_Target.length);
    
     for(uint8 i=0; i<_Target.length; i++){
            _temp[i].TargetAddress=_Target[i];
            _temp[i].TrxAmount=_amnt[i];
        }
    _Trxpoolhash=keccak256(abi.encode(_temp));

    require(_Trxpoolhash==TrxPoolHash,"Transactions not Match");

    if (ApproveQty==1 || SignQty==2)
    {
        require(L2Signed!=msg.sender,"Double Sign Not Allowed");
        ExecuteTrx();
        delete TrxPool;
        TrxPoolStatus=1;
        SignQty=1;
        L2Signed=address(0);
    }
    else
    {
    SignQty=2;
    TrxPoolStatus=3;
    L2Signed=msg.sender;
    }
}
function SetUpContract (address[] memory L1Key, address[] memory L2Key, address ERC20_addr) public onlyOwner {
    KeyList memory _Temp;
    if (Layer1OPKeys.length>0) {
        delete Layer1OPKeys;
        delete Layer2OPKeys;
    }

    require(L1Key.length<4,"Maxium L1Opkey Qty is 3");
    require(L2Key.length<4,"Maxium L2Opkey Qty is 3");
    ERCType=ERC20_addr;

   for(uint8 i=0;i<L1Key.length;i++) {
            _Temp.KeyAddr=L1Key[i];
            _Temp.Flag=true;
            Layer1OPKeys.push(_Temp);
   }
   for(uint8 i=0;i<L2Key.length;i++) {
            _Temp.KeyAddr=L2Key[i];
            _Temp.Flag=true;
            Layer2OPKeys.push(_Temp);
        }
}

function CancelAllTrx() public {
    require(CheckKey(msg.sender,Layer2OPKeys)||msg.sender==owner(),"Only L2OPKey can do this");
    delete TrxPool;
    TrxPoolStatus=1;
    SignQty=1;
    L2Signed=address(0);
}

function DeactivateL1Key(uint i) public {
    require(i<Layer1OPKeys.length,"Over Boundry");
    require(CheckKey(msg.sender,Layer2OPKeys) || msg.sender == owner(),"Not Authorized");
    Layer1OPKeys[i].Flag= false;
}
function DeactivateL2Key(uint i) public {
    require(i<Layer2OPKeys.length,"Over Boundry");
    require(CheckKey(msg.sender,Layer2OPKeys) || msg.sender == owner(),"Not Authorized");
    Layer2OPKeys[i].Flag= false;
}

function ReplaceL1Key(uint i,address _key) public {
    require(i<Layer1OPKeys.length, "Over Boundry");
    require(CheckKey(msg.sender,Layer2OPKeys) || msg.sender == owner(),"Not Authorized");
    Layer1OPKeys[i].KeyAddr=_key;
    Layer1OPKeys[i].Flag=true;
}
function ReplaceL2Key(uint i,address _key) public {
    require(i<Layer2OPKeys.length,"Over Boundry");
    require(CheckKey(msg.sender,Layer2OPKeys) || msg.sender == owner(),"Not Authorized");
    Layer2OPKeys[i].KeyAddr=_key;
    Layer2OPKeys[i].Flag=true;
}

}