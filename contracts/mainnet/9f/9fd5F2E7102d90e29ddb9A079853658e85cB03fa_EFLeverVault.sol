/**
 *Submitted for verification at Etherscan.io on 2022-05-24
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

// File: contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.4.21 <0.6.0;

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
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

interface ERC20Property{
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
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

// File: contracts/core/Interfaces.sol

pragma solidity >=0.4.21 <0.6.0;

interface IWETH {
    function withdraw(uint256) external;
}
interface IAAVE {
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function getUserAccountData(address)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface ILido {
    function submit(address) external payable;
}

interface IBalancer {
    function flashLoan(
        address recipient,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata userData
    ) external;
}

interface IBalancerFee{
    function getFlashLoanFeePercentage() external view returns (uint256);//18 decimal
}

interface ICurve{
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}

// File: contracts/core/EFLeverVault.sol

pragma solidity >=0.4.21 <0.6.0;







contract TokenInterfaceERC20{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

contract EFLeverVault is Ownable, ReentrancyGuard{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Address for address;

  uint256 public constant ratio_base = 10000;

  uint256 public mlr;
  address payable public fee_pool;
  address public ef_token;
  uint256 public last_earn_block;

  uint256 public block_rate;
  uint256 last_volume;
  uint256 last_st;
  uint256 last_e;
  uint256 temp;


  address public aave = address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  address public balancer = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public balancer_fee = address(0xce88686553686DA562CE7Cea497CE749DA109f9F);
  address public lido = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  address public asteth = address(0x1982b2F5814301d4e9a8b0201555376e62F82428);
  address public curve_pool = address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
  address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  bool public is_paused;

  //@param _crv, means ETH if it's 0x0
  constructor(address _ef_token) public {
    ef_token = _ef_token;
    mlr = 6750;
    last_earn_block = block.number;
  }

  function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) public payable {
        require(msg.sender == balancer, "only flashloan vault");

        uint256 loan_amount = amounts[0];
        uint256 fee_amount = feeAmounts[0];

        if (keccak256(userData) == keccak256("0x1")){
          _deposit(loan_amount, fee_amount);
        }
        if (keccak256(userData) == keccak256("0x2")){
          _withdraw(loan_amount, fee_amount);
        }
    }

  event CFFDeposit(address from, uint256 eth_amount, uint256 ef_amount, uint256 virtual_price);

  function getFeeParam() public view returns(uint256){
    return IBalancerFee(balancer_fee).getFlashLoanFeePercentage().safeDiv(1e14).safeAdd(ratio_base); //10000(1+fee/1e18) 
  }

  function getCollecteral() public view returns(uint256){ //decimal 18
    if (is_paused) return address(this).balance;
    (uint256 c, , , , ,) = IAAVE(aave).getUserAccountData(address(this));
    return c;
  }
  function getDebt() public view returns(uint256){ //decimal 18
    ( , uint256 d, , , ,) = IAAVE(aave).getUserAccountData(address(this));
    return d;
  }
  function getVolume() public view returns(uint256){
    return getCollecteral().safeSub(getDebt());
  }
  function getVirtualPrice() public view returns(uint256){
    if (IERC20(ef_token).totalSupply() == 0) {return 0;}
    return getVolume().safeMul(1e18).safeDiv(IERC20(ef_token).totalSupply());
  }

  function deposit(uint256 _amount) public payable nonReentrant{
    require(!is_paused, "paused");
    require(_amount == msg.value, "inconsist amount");
    require(_amount != 0, "too small amount");
    
    uint256 volume_before = getVolume();
    if (volume_before < 1e9) {require(_amount >= 1e16, "Too small initial amount");}

    uint256 fee_para = getFeeParam();
    uint256 loan_amount = mlr.safeMul(_amount).safeDiv(fee_para.safeSub(mlr));//mx/(a-m)
    uint256 fee_amount = loan_amount.safeMul(fee_para.safeSub(10000)).safeDiv(10000);

    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
      
    bytes memory userData = "0x1";

    tokens[0] = weth;
    amounts[0] = loan_amount;
    
    IBalancer(balancer).flashLoan(address(this), tokens, amounts, userData);
    uint256 ef_amount;
    if ((volume_before < 1e9)){
      ef_amount = _amount.safeSub(fee_amount);
    }
    else{
      ef_amount = _amount.safeSub(fee_amount).safeMul(IERC20(ef_token).totalSupply()).safeDiv(volume_before);
    }
    TokenInterfaceERC20(ef_token).generateTokens(msg.sender, ef_amount);
    emit CFFDeposit(msg.sender, _amount, ef_amount, getVirtualPrice());
  }

  function _deposit(uint256 amount, uint256 fee_amount) internal{
    IWETH(weth).withdraw(amount);
    ILido(lido).submit.value(address(this).balance)(address(this));

    uint256 lido_bal = IERC20(lido).balanceOf(address(this));
    if (IERC20(lido).allowance(address(this), aave) != 0) {IERC20(lido).safeApprove(aave, 0);}
    IERC20(lido).safeApprove(aave, lido_bal);
    IAAVE(aave).deposit(lido, lido_bal, address(this), 0);

    uint256 to_repay = amount.safeAdd(fee_amount);
    IAAVE(aave).borrow(weth, to_repay, 2, 0, address(this));
    IERC20(weth).safeTransfer(balancer, to_repay);
  }

  event CFFWithdraw(address from, uint256 eth_amount, uint256 ef_amount, uint256 virtual_price);
  function withdraw(uint256 _amount) public nonReentrant{
    require(IERC20(ef_token).balanceOf(msg.sender) >= _amount, "not enough balance");
    if (is_paused){
      uint256 to_send = address(this).balance.safeMul(_amount).safeDiv(IERC20(ef_token).totalSupply());
      (bool status, ) = msg.sender.call.value(to_send)("");
      require(status, "transfer eth failed");
      TokenInterfaceERC20(ef_token).destroyTokens(msg.sender, _amount);
      return;
    }
    uint256 loan_amount = getDebt().safeMul(_amount).safeDiv(IERC20(ef_token).totalSupply());
    
    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes memory userData = "0x2";
    tokens[0] = weth;
    amounts[0] = loan_amount;
    //uint256 user_eth_before = msg.sender.balance;
    IBalancer(balancer).flashLoan(address(this), tokens, amounts, userData);

    uint256 to_send = address(this).balance;
    (bool status, ) = msg.sender.call.value(to_send)("");
    require(status, "transfer eth failed");

    TokenInterfaceERC20(ef_token).destroyTokens(msg.sender, _amount);
    emit CFFWithdraw(msg.sender, to_send, _amount, getVirtualPrice());
  }
  //1. rapay aave with flashloaned amount,    mx
  //2. withdraw steth with current ltv,  x
  //3. change all steths to eths,    x         
  //4. repay flashloan.   pay amx, left x-amx eth
  function _withdraw(uint256 amount, uint256 fee_amount) internal{
    uint256 steth_amount = amount.safeMul(IERC20(asteth).balanceOf(address(this))).safeDiv(getDebt());
    if (IERC20(weth).allowance(address(this), aave) != 0) {IERC20(weth).safeApprove(aave, 0);}
    IERC20(weth).safeApprove(aave, amount);

    IAAVE(aave).repay(weth, amount, 2, address(this));
    IAAVE(aave).withdraw(lido, steth_amount, address(this));

    if (IERC20(lido).allowance(address(this), curve_pool) != 0) {IERC20(lido).safeApprove(curve_pool, 0);}
    IERC20(lido).safeApprove(curve_pool, steth_amount);
    ICurve(curve_pool).exchange(1, 0, steth_amount, 0);

    (bool status, ) = weth.call.value(amount.safeAdd(fee_amount))("");
    require(status, "transfer eth failed");
    IERC20(weth).safeTransfer(balancer, amount.safeAdd(fee_amount));
  }
  event EFPause(uint256 eth_amount, uint256 virtual_price);
  function pause() public onlyOwner{
    require(!is_paused, "paused");
    uint256 loan_amount = getDebt();
    
    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes memory userData = "0x2";
    tokens[0] = weth;
    amounts[0] = loan_amount;
    IBalancer(balancer).flashLoan(address(this), tokens, amounts, userData);
    is_paused = true;
    emit EFPause(address(this).balance, getVirtualPrice());
  }

  event EFRestart(uint256 eth_amount, uint256 virtual_price);
  function restart() public onlyOwner{
    require(is_paused, "not pause");

    uint256 _amount = address(this).balance;
    uint256 fee_para = getFeeParam();
    uint256 loan_amount = mlr.safeMul(_amount).safeDiv(fee_para.safeSub(mlr));//mx/(a-m)

    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes memory userData = "0x1";
    tokens[0] = weth;
    amounts[0] = loan_amount;
    IBalancer(balancer).flashLoan(address(this), tokens, amounts, userData);
    is_paused = false;
    emit EFRestart(_amount, getVirtualPrice());
  }


  event ActualLTVChanged(uint256 debt_before, uint256 collecteral_before, uint256 debt_after, uint256 collecteral_after);
  function reduceActualLTV() public onlyOwner{
    uint256 e = getDebt();
    uint256 st = getCollecteral();    
    require(e.safeMul(10000) > st.safeMul(mlr), "no need to reduce");
    uint256 x = (e.safeMul(10000).safeSub(st.safeMul(mlr))).safeDiv(uint256(10000).safeSub(mlr));//x = (E-mST)/(1-m)

    uint256 loan_amount = x.safeMul(getDebt()).safeDiv(getCollecteral());
    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes memory userData = "0x2";
    tokens[0] = weth;
    amounts[0] = loan_amount;
    IBalancer(balancer).flashLoan(address(this), tokens, amounts, userData);

    (bool status, ) = weth.call.value(address(this).balance)("");
    require(status, "transfer eth failed");
    
    if (IERC20(weth).allowance(address(this), aave) != 0) {IERC20(weth).safeApprove(aave, 0);}
    IERC20(weth).safeApprove(aave, IERC20(weth).balanceOf(address(this)));
    IAAVE(aave).repay(weth, IERC20(weth).balanceOf(address(this)), 2, address(this));
    emit ActualLTVChanged(e, st, getDebt(), getCollecteral());
  }

  function raiseActualLTV(uint256 lt) public onlyOwner{//take lt = 7500
    uint256 e = getDebt();
    uint256 st = getCollecteral();    
    require(e.safeMul(10000) < st.safeMul(mlr), "no need to raise");
    uint256 x = st.safeMul(mlr).safeSub(e.safeMul(10000)).safeDiv(uint256(10000).safeSub(mlr));//x = (mST-E)/(1-m)
    uint256 y = st.safeMul(lt).safeDiv(10000).safeSub(e).safeSub(1);
    if (x > y) {x = y;}
    IAAVE(aave).borrow(weth, x, 2, 0, address(this));
    IWETH(weth).withdraw(IERC20(weth).balanceOf(address(this)));
    ILido(lido).submit.value(address(this).balance)(address(this));

    if (IERC20(lido).allowance(address(this), aave) != 0) {IERC20(lido).safeApprove(aave, 0);}
    IERC20(lido).safeApprove(aave, IERC20(lido).balanceOf(address(this)));
    IAAVE(aave).deposit(lido, IERC20(lido).balanceOf(address(this)), address(this), 0);

    emit ActualLTVChanged(e, st, getDebt(), getCollecteral());
  }
  event EFEarnReward(uint256 eth_amount, uint256 ef_amount);
  function earnReward() public onlyOwner{
    if (fee_pool == address(0x0)) return;
    uint256 len = block.number.safeSub(last_earn_block);
    uint256 A = last_volume.safeMul(block_rate).safeMul(len).safeDiv(1e18);
    uint256 B = getVolume().safeMul(block_rate).safeMul(len).safeDiv(1e18);
 
    uint256 st_fee;
    if (A <= B){
      st_fee = A.safeAdd(B).safeDiv(2);
    }
    else{
      st_fee = B;
    }
    st_fee = st_fee.safeSub(st_fee.safeMul(IERC20(ef_token).balanceOf(fee_pool)).safeDiv(IERC20(ef_token).totalSupply()));
    uint256 ef_amount = st_fee.safeMul(IERC20(ef_token).totalSupply()).safeDiv(getVolume().safeSub(st_fee));
    TokenInterfaceERC20(ef_token).generateTokens(fee_pool, ef_amount);
    last_volume = getVolume();
    last_earn_block = block.number;

    emit EFEarnReward(st_fee, ef_amount);
  }

  event ChangeMaxLoanRate(uint256 old, uint256 _new);
  function changeMaxLoanRate(uint256 _new) public onlyOwner{
    uint256 old = mlr;
    mlr = _new;
    emit ChangeMaxLoanRate(old, _new);
  }

  event ChangeBlockRate(uint256 old, uint256 _new);
  function changeBlockRate(uint256 _r) public onlyOwner{//18 decimal, 2102400 blocks in a year
    uint256 old = block_rate;
    block_rate = _r;
    emit ChangeBlockRate(old, _r);
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address payable _fp) public onlyOwner{
    address old = fee_pool;
    fee_pool = _fp;
    emit ChangeFeePool(old, fee_pool);
  }

  function callWithData(address payable to, bytes memory data, uint256 amount)public payable onlyOwner{
    (bool status, ) = to.call.value(amount)(data);
    require(status, "call failed");
  }

  function delegateCallWithData(address payable to, bytes memory data)public payable onlyOwner{
    (bool status, ) = to.delegatecall(data);
    require(status, "call failed");
  }


  function() external payable{}
  }

contract EFLeverVaultFactory{
  event NewEFLeverVault(address addr);

  function createEFLeverVault(address _ef_token) public returns(address){
    EFLeverVault cf = new EFLeverVault(_ef_token);
    cf.transferOwnership(msg.sender);
    emit NewEFLeverVault(address(cf));
    return address(cf);
  }

}