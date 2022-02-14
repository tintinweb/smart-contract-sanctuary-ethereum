/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/core/market/interface/DataMarketPlaceInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract DataMarketPlaceInterface{
  address public payment_token;
  function delegateCallUseData(address _e, bytes memory data) public returns(bytes memory);
}

// File: contracts/plugins/GasRewardTool.sol

pragma solidity >=0.4.21 <0.6.0;

contract GasRewardInterface{
  function reward(address payable to, uint256 amount) public;
}

contract GasRewardTool is Ownable{
  GasRewardInterface public gas_reward_contract;

  modifier rewardGas{
    uint256 gas_start = gasleft();
    _;
    uint256 gasused = (gas_start - gasleft()) * tx.gasprice;
    if(gas_reward_contract != GasRewardInterface(0x0)){
      gas_reward_contract.reward(tx.origin, gasused);
    }
  }

  event ChangeRewarder(address _old, address _new);
  function changeRewarder(address _rewarder) public onlyOwner{
    address old = address(gas_reward_contract);
    gas_reward_contract = GasRewardInterface(_rewarder);
    emit ChangeRewarder(old, _rewarder);
  }
}

// File: contracts/core/PaymentConfirmTool.sol

pragma solidity >=0.4.21 <0.6.0;


contract IPaymentProxy{
  function startTransferRequest() public returns(bytes32);
  function endTransferRequest() public returns(bytes32);
  function currentTransferRequestHash() public view returns(bytes32);
  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8);
}
contract PaymentConfirmTool is Ownable{
  address confirm_proxy;

  event PaymentConfirmRequest(bytes32 hash);
  modifier need_confirm{
    if(confirm_proxy != address(0x0)){
      bytes32 local = IPaymentProxy(confirm_proxy).startTransferRequest();
      _;
      require(local == IPaymentProxy(confirm_proxy).endTransferRequest(), "invalid nonce");
      emit PaymentConfirmRequest(local);
    }else{
      _;
    }
  }

  //@return 0 is init or pending, 1 is for succ, 2 is for fail
  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8){
    return IPaymentProxy(confirm_proxy).getTransferRequestStatus(_hash) ;
  }

  event ChangeConfirmProxy(address old_proxy, address new_proxy);
  function changeConfirmProxy(address new_proxy) public onlyOwner{
    address old = confirm_proxy;
    confirm_proxy = new_proxy;
    emit ChangeConfirmProxy(old, new_proxy);
  }

}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/utils/Address.sol

pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/erc20/SafeERC20.sol

pragma solidity >=0.4.21 <0.6.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/core/market/common/SGXDataMarketCommon.sol

pragma solidity >=0.4.21 <0.6.0;








interface IMarketCommon{
  function createStaticData(bytes32 _hash,
                            string calldata _extra_info,
                            uint _price,
                            bytes calldata _pkey,
                            bytes calldata _pkey_sig,
                            bytes calldata _hash_sig) external returns(bytes32);
  function removeStaticData(bytes32 _vhash) external ;
  function changeDataOwner(bytes32 _vhash, address payable _new_owner) external ;
  function transferRequestOwnership(bytes32 _vhash, bytes32 request_hash, address payable new_owner) external;
  function rejectRequest(bytes32 _vhash, bytes32 request_hash) external;
  function changeRequestRevokeBlockNum(bytes32 _vhash, uint256 _new_block_num) external;
  function getDataOwner(bytes32 _vhash) external returns(address);
  function getRequestOwner(bytes32 _vhash, bytes32 request_hash) external returns(address);
}

contract SGXDataMarketCommon is Ownable, GasRewardTool, PaymentConfirmTool{
  DataMarketPlaceInterface public market;

  address public data_lib_address;

  event ChangeMarket(address old_market, address new_market);
  function changeMarket(address _market) public onlyOwner{
    address old = address(market);
    market = DataMarketPlaceInterface(_market);
    emit ChangeMarket(old, address(market));
  }

  event ChangeDataLib(address old_lib, address new_lib);
  function changeDataLib(address _new_lib) public onlyOwner{
    address old = data_lib_address;
    data_lib_address = _new_lib;
    emit ChangeDataLib(old, data_lib_address);
  }

  event SDMarketNewStaticData(bytes32 indexed vhash, bytes32 indexed data_hash, string extra_info, uint price, bytes pkey, bytes pkey_sig, bytes hash_sig);
  function createStaticData(bytes32 _hash,
                            string memory _extra_info,
                            uint _price,
                            bytes memory _pkey,
                            bytes memory _pkey_sig,
                            bytes memory _hash_sig) public rewardGas need_confirm returns(bytes32){

    bytes32 vhash;
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.createStaticData.selector, _hash, _extra_info, _price, _pkey, _pkey_sig, _hash_sig);
      bytes memory ret = market.delegateCallUseData(data_lib_address, data);
      (vhash) = abi.decode(ret, (bytes32));
    }

    change_data_owner(vhash, msg.sender);

    emit SDMarketNewStaticData(vhash, _hash, _extra_info, _price, _pkey, _pkey_sig, _hash_sig);
    return vhash;
  }

  event SDMarketRemoveData(bytes32 indexed vhash);
  function removeStaticData(bytes32 _vhash) public rewardGas{
    address owner = getDataOwner(_vhash);
    require(owner == msg.sender, "only owner may remove it");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    bytes memory data = abi.encodeWithSelector(dl.removeStaticData.selector, _vhash);
    emit SDMarketRemoveData(_vhash);
  }

  event SDMarketChangeDataOwner(bytes32 indexed vhash, address owner);
  function changeDataOwner(bytes32 _vhash, address payable _new_owner) public{
    address owner = getDataOwner(_vhash);
    require(owner == msg.sender, "only owner may change ownership");

    change_data_owner(_vhash, _new_owner);
    emit SDMarketChangeDataOwner(_vhash, _new_owner);
  }
  function change_data_owner(bytes32 _vhash, address payable _new_owner) internal{
    IMarketCommon dl = IMarketCommon(data_lib_address);
    bytes memory data = abi.encodeWithSelector(dl.changeDataOwner.selector, _vhash, _new_owner);
    market.delegateCallUseData(data_lib_address, data);

  }

  event SDMarketTransferRequestOwner(address old_owner, address new_owner);
  function transferRequestOwnership(bytes32 _vhash, bytes32 request_hash, address payable new_owner) public{
    address request_owner = getRequestOwner(_vhash, request_hash);
    require(request_owner == msg.sender, "only request owner can transfer");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    bytes memory data = abi.encodeWithSelector(dl.transferRequestOwnership.selector, _vhash, request_hash, new_owner);
    market.delegateCallUseData(data_lib_address, data);
    emit SDMarketTransferRequestOwner(msg.sender, new_owner);
  }

  function getDataOwner(bytes32 _vhash) public returns(address){
    address owner;
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.getDataOwner.selector, _vhash);
      bytes memory ret = market.delegateCallUseData(data_lib_address, data);
      (owner) = abi.decode(ret, (address));
    }
    return owner;
  }

  function getRequestOwner(bytes32 _vhash, bytes32 request_hash) public returns(address){
    address owner;
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.getRequestOwner.selector, _vhash, request_hash);
      bytes memory ret = market.delegateCallUseData(data_lib_address, data);
      (owner) = abi.decode(ret, (address));
    }
    return owner;
  }

  event SDMarketRejectRequest(bytes32 indexed vhash, bytes32 indexed request_hash);
  function rejectRequest(bytes32 _vhash, bytes32 request_hash) public rewardGas need_confirm{
    address data_owner = getDataOwner(_vhash);
    require(data_owner == msg.sender, "only data owner may reject");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.rejectRequest.selector, _vhash, request_hash);
      market.delegateCallUseData(data_lib_address, data);
    }
    emit SDMarketRejectRequest(_vhash, request_hash);
  }

  event SDMarketChangeRequestRevokeBlockNum(bytes32 indexed vhash, uint256 block_num);
  function changeRequestRevokeBlockNum(bytes32 _vhash, uint256 _new_block_num) public rewardGas{
    address data_owner = getDataOwner(_vhash);
    require(data_owner == msg.sender, "only data owner may change request block number");
    IMarketCommon dl = IMarketCommon(data_lib_address);
    {
      bytes memory data = abi.encodeWithSelector(dl.changeRequestRevokeBlockNum.selector, _vhash, _new_block_num);
      market.delegateCallUseData(data_lib_address, data);
    }
    emit SDMarketChangeRequestRevokeBlockNum(_vhash, _new_block_num);
  }

}