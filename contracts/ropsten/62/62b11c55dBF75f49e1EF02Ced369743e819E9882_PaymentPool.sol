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

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;


contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools is Ownable{
  TrustListInterface public trustlist;

  modifier is_trusted(address addr){
    require(trustlist != TrustListInterface(0x0), "trustlist is 0x0");
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

  event ChangeTrustList(address _old, address _new);
  function changeTrustList(address _addr) public onlyOwner{
    address old = address(trustlist);
    trustlist = TrustListInterface(_addr);
    emit ChangeTrustList(old, _addr);
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

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            (bool status, ) = to.call.value(address(this).balance)("");
            require(status, "TokenClaimer transfer eth failed");
            return;
        }
        uint balance = IERC20(_token).balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/core/IPERC20.sol

pragma solidity >=0.4.21 <0.6.0;


interface IPERC {
  function confirmTransfer(address _to, uint256 _amount) external returns (bool);
  function is_proxy_required() external view returns(bool);
  function burn(address _owner, uint _amount) external returns(bool);
}

// File: contracts/erc20/TokenInterface.sol

pragma solidity >=0.4.21 <0.6.0;
contract TokenInterface{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
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

// File: contracts/utils/AddressArray.sol

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] memory self, address addr) public pure returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] memory self, address addr) public pure returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
    return true;
  }
}

// File: contracts/core/PaymentPool.sol

pragma solidity >=0.4.21 <0.6.0;










contract PaymentPool is Ownable, TokenClaimer, TrustListTools{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using AddressArray for address[];

  string public bank_name;
  uint256 public nonce;
  bool public tx_lock;

  address[] involved_tokens;
  address[][] involved_addr;
  uint256[][] old_balance;

  struct receipt{
    address addr;
    uint256 amount;
    address token;
    bool status;//true for receiver, false for sender
  }

  struct request_info{
    bool exist;
    address from;
    uint8 status; //0 is init or pending, 1 is for succ, 2 is for fail
    receipt[] receipts;
  }
  mapping (bytes32 => request_info) public requests;
  mapping (address => mapping (address => uint256)) public pending_balance;
  mapping (bytes32 => uint256) public pending_asset;

  event withdraw_token(address token, address to, uint256 amount);
  event issue_token(address token, address to, uint256 amount);

  event RecvETH(uint256 v);
  function() external payable{
    emit RecvETH(msg.value);
  }

  constructor(string memory name) public{
    bank_name = name;
    nonce = 0;
  }


  function claimStdTokens(address _token, address payable to)
    public onlyOwner{
      _claimStdTokens(_token, to);
  }

  function balance(address erc20_token_addr) public view returns(uint){
    if(erc20_token_addr == address(0x0)){
      return address(this).balance;
    }
    return IERC20(erc20_token_addr).balanceOf(address(this));
  }

  function transfer(address erc20_token_addr, address payable to, uint tokens)
    public
    onlyOwner
    returns (bool success){
    require(tokens <= balance(erc20_token_addr), "Pool not enough tokens");
    if(erc20_token_addr == address(0x0)){
      (bool _success, ) = to.call.value(tokens)("");
      require(_success, "Pool transfer eth failed");
      emit withdraw_token(erc20_token_addr, to, tokens);
      return true;
    }
    IERC20(erc20_token_addr).safeTransfer(to, tokens);
    emit withdraw_token(erc20_token_addr, to, tokens);
    return true;
  }

  function startTransferRequest() public is_trusted(msg.sender) returns(bytes32){
    require(!tx_lock, "startTransferRequest cannot be nested");
    tx_lock = true;
    nonce ++;
    bytes32 h = currentTransferRequestHash();
    requests[h].exist = true;
    requests[h].from = msg.sender;
    requests[h].status = 1; //by default, it's succ until we get transfer requests.
    return h;
  }

  function endTransferRequest() public is_trusted(msg.sender) returns(bytes32){

    bytes32 h = currentTransferRequestHash();
    for (uint k = 0; k < involved_tokens.length;k++){
      address token_addr = involved_tokens[k];
      for (uint i = 0;i < involved_addr[k].length; i++){
        address addr = involved_addr[k][i];
        uint256 bal = IERC20(token_addr).balanceOf(addr);
        if (bal < old_balance[k][i]){
          TokenInterface(token_addr).generateTokens(address(this), old_balance[k][i].safeSub(bal));
          receipt storage recp = requests[h].receipts[requests[h].receipts.length++];
          recp.token = token_addr;
          recp.addr = addr;
          recp.amount = old_balance[k][i].safeSub(bal);
          recp.status = false;
          pending_balance[addr][token_addr] = pending_balance[addr][token_addr].safeAdd(old_balance[k][i].safeSub(bal));
        }
        else if (bal > old_balance[k][i]){
          TokenInterface(token_addr).destroyTokens(addr, bal.safeSub(old_balance[k][i]));
          receipt storage recp = requests[h].receipts[requests[h].receipts.length ++];
          recp.token = token_addr;
          recp.addr = addr;
          recp.amount = bal.safeSub(old_balance[k][i]);
          recp.status = true;
        }
      }
    }
    delete old_balance;
    delete involved_tokens;
    delete involved_addr;
    tx_lock = false;
    return keccak256(abi.encodePacked(nonce));
  }

  function currentTransferRequestHash() public view returns(bytes32){
    return keccak256(abi.encodePacked(nonce));
  }

  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8){
    return requests[_hash].status;
  }

  function getPendingBalance(address _owner, address token_addr) public view returns(uint256){
    return pending_balance[_owner][token_addr];
  }

  event TransferRequest(bytes32 request_hash, address token_addr, address from, address to, uint256 amount);

  function transferRequest(address token_addr, address _from, address _to, uint256 _amount) public is_trusted(msg.sender){
    bytes32 h = currentTransferRequestHash();
    if (IPERC(token_addr).is_proxy_required()) {
      require(tx_lock, "proxy required");
      if (!involved_tokens.exists(token_addr)){
        involved_tokens.push(token_addr);
        address[] memory a;
        involved_addr.push(a);
        uint256[] memory b;
        old_balance.push(b);
      }
      uint256 ind = involved_tokens.index_of(token_addr);
      if (!involved_addr[ind].exists(_from)){
        involved_addr[ind].push(_from);
        old_balance[ind].push(IERC20(token_addr).balanceOf(_from));
      }
      if (!involved_addr[ind].exists(_to)){  
        involved_addr[ind].push(_to);
        old_balance[ind].push(IERC20(token_addr).balanceOf(_to));
      }
      emit TransferRequest(h, token_addr, _from, _to, _amount);
    }
    else{
      //IPERC(token_addr).confirmTransfer(_to, _amount);
      //do nothing
    }
  }

  function transferCommit(bytes32 _hash, bool _status) public is_trusted(msg.sender){
    request_info storage request = requests[_hash];
    if(_status){
      request.status = 1;
    }else{
      request.status = 2;
    }
    if (_status){
      for (uint i = 0; i < request.receipts.length; i++){
        receipt memory rt = request.receipts[i];
        if (rt.status == false) continue;
        if (rt.addr != address(0x1)){
          IPERC(rt.token).confirmTransfer(rt.addr, rt.amount);}
        else{
          IPERC(rt.token).confirmTransfer(address(0), rt.amount);
        }
      }
    }
    else {
      for (uint i = 0; i < request.receipts.length; i++){
        receipt memory rt = request.receipts[i];
        if (rt.status == true) continue;
        IPERC(rt.token).confirmTransfer(rt.addr, rt.amount);
      }
    }
    for (uint i = 0; i < request.receipts.length; i++){
      receipt memory rt = request.receipts[i];
      if (rt.status == true) continue;
      pending_balance[rt.addr][rt.token] = pending_balance[rt.addr][rt.token].safeSub(rt.amount);
    }
  }

}


contract PaymentPoolFactory {
  event CreatePaymentPool(string name, address addr);

  function newPaymentPool(string memory name) public returns(address){
    PaymentPool addr = new PaymentPool(name);
    emit CreatePaymentPool(name, address(addr));
    addr.transferOwnership(msg.sender);
    return address(addr);
  }
}