/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/interfaces/IBondCalculator.sol


pragma solidity 0.7.5;

interface IBondCalculator {
    function valuation(address _LP, uint256 _amount)
        external
        view
        returns (uint256);

    function markdown(address _LP) external view returns (uint256);
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/interfaces/IOwnable.sol


pragma solidity 0.7.5;


interface IOwnable {
  function owner() external view returns (address);
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/utils/Ownable.sol


pragma solidity 0.7.5;


abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }
    
    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/interfaces/IERC20.sol


pragma solidity 0.7.5;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/libraries/Address.sol


pragma solidity 0.7.5;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/libraries/SafeMath.sol


pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/libraries/SafeERC20.sol


pragma solidity 0.7.5;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/staking/Treasury.sol


pragma solidity 0.7.5;






interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}

contract OlympusTreasury is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event ReservesManaged(address indexed token, uint256 amount);
    event ReservesUpdated(uint256 indexed totalReserves);
    event ReservesAudited(uint256 indexed totalReserves);
    event RewardsMinted(
        address indexed caller,
        address indexed recipient,
        uint256 amount
    );
    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(
        MANAGING indexed managing,
        address activated,
        bool result
    );

    enum MANAGING {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        REWARDMANAGER,
        SOHM,
        CUSTOMTOKENDEPOSITOR,
        CUSTOMTOKEN,
        CUSTOMTOKENSPENDER
    }

    address public immutable OHM;

    address[] public customDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isCustomDepositor;

    address[] public customSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isCustomSpender;

    address[] public customTokens;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping(address => bool) public isReserveToken;

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveDepositor;

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveSpender;

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping(address => bool) public isLiquidityToken;

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityDepositor;

    address public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isReserveManager;

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isLiquidityManager;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping(address => bool) public isRewardManager;
    // Push only, beware false-positives.
    mapping(address => bool) public isCustomToken;

    address public sOHM;

    uint256 public totalReserves; // Risk-free value of all assets
    uint256 public totalDebt;

    //why we are pushing dai token to reservetoken??
    //.

    constructor(address _OHM, address _DAI) {
        require(_OHM != address(0));
        OHM = _OHM;

        isReserveToken[_DAI] = true;
        reserveTokens.push(_DAI);
    }

    /**
        @notice allow approved address to deposit an asset for OHM
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 send_) {
        require(
            isReserveToken[_token] ||
                isLiquidityToken[_token] ||
                isCustomToken[_token],
            "Not accepted"
        );
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        //why we are applying these conditiond after transferring tokens?

        if (isReserveToken[_token]) {
            require(isReserveDepositor[msg.sender], "Not approved");
        } else if (isLiquidityToken[_token]) {
            require(isLiquidityDepositor[msg.sender], "Not approved");
        } else {
            require(isCustomDepositor[msg.sender], "Not Approved");
        }

        uint256 value = valueOf(_token, _amount);
        // mint OHM needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        IERC20Mintable(OHM).mint(msg.sender, send_);

        totalReserves = totalReserves.add(value);
        emit ReservesUpdated(totalReserves);

        emit Deposit(_token, _amount, value);
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        require(isReserveToken[_token], "Not accepted"); // Only reserves can be used for redemptions
        require(isReserveSpender[msg.sender] == true, "Not approved");

        uint256 value = valueOf(_token, _amount);
        IOHMERC20(OHM).burnFrom(msg.sender, value);

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, value);
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */

    // what is this function for
    function manage(address _token, uint256 _amount) external {
        if (isLiquidityToken[_token]) {
            require(isLiquidityManager[msg.sender], "Not approved");
        } else {
            require(isReserveManager[msg.sender], "Not approved");
        }

        uint256 value = valueOf(_token, _amount);
        require(value <= excessReserves(), "Insufficient reserves");

        totalReserves = totalReserves.sub(value);
        emit ReservesUpdated(totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit ReservesManaged(_token, _amount);
    }

    /**
        @notice send epoch reward to staking contract
     */

    //minting manually?
    function mintRewards(address _recipient, uint256 _amount) external {
        require(isRewardManager[msg.sender], "Not approved");
        require(_amount <= excessReserves(), "Insufficient reserves");

        IERC20Mintable(OHM).mint(_recipient, _amount);

        emit RewardsMinted(msg.sender, _recipient, _amount);
    }

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns (uint256) {
        return totalReserves.sub(IERC20(OHM).totalSupply().sub(totalDebt));
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves0 before audit
     */
    function auditReserves() external onlyOwner {
        uint256 reserves;
        for (uint256 i = 0; i < reserveTokens.length; i++) {
            reserves = reserves.add(
                valueOf(
                    reserveTokens[i],
                    IERC20(reserveTokens[i]).balanceOf(address(this))
                )
            );
        }
        for (uint256 i = 0; i < liquidityTokens.length; i++) {
            reserves = reserves.add(
                valueOf(
                    liquidityTokens[i],
                    IERC20(liquidityTokens[i]).balanceOf(address(this))
                )
            );
        }
        totalReserves = reserves;
        emit ReservesUpdated(reserves);
        emit ReservesAudited(reserves);
    }

    /**
        @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */

    //the formula is just ensuring that we get the amount as per ohm decimals

    function valueOf(address _token, uint256 _amount)
        public
        view
        virtual
        returns (uint256 value_)
    {
        if (isReserveToken[_token]) {
            // convert amount to match OHM decimals
            value_ = _amount.mul(10**IERC20(OHM).decimals()).div(
                10**IERC20(_token).decimals()
            );
        } else if (isLiquidityToken[_token]) {
            value_ = IBondCalculator(bondCalculator).valuation(_token, _amount);
        }
    }
}

// File: Desktop/Blockchain/ACX/AlchemiCryptoExchange-master-20220404T060238Z-001/AlchemiCryptoExchange-master/contracts/staking/TreasuryV2.sol


pragma solidity 0.7.5;



//interface of factory contract for gettingpair function, will return a single pair address
interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

//interfcae of lptoken contract for getreserves, token0, and token1 funtcions .
//getreserve funvtion will return the tow reserves in uint and blocktimestamp.
//token0 will return the contract assress.
//token  will return the contract address.

interface ILpToken {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//interfaces of router contract giving us the the quote function
//the quote function will have amount, and reserve A and reserve B as parameters.
//will return a new amount

interface IRouter {
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

//start of the contract
contract TreasuryV2 is OlympusTreasury {
    using SafeMath for uint256;

    address public Factory;
    address public Router;
    address public DAI;

    //giving the OHM and DAI value in contructor
    //ohm?
    constructor(address _OHM, address _DAI) OlympusTreasury(_OHM, _DAI) {
        DAI = _DAI;
    }

    //setting up the the nterfcae address in contrutor of factory and router token

    function _initialize(address _factory, address _router) public onlyOwner {
        Factory = _factory;
        Router = _router;
    }

    function valueOf(address _token, uint256 _amount)
        public
        view
        override
        returns (uint256 value_)
    {
        uint112 _customTokenReserve;
        uint112 _busdTokenReserve;
        uint32 _blockTimestampLast;
        if (isCustomToken[_token]) {
            address LpToken = IFactory(Factory).getPair(_token, DAI);
            require(LpToken != address(0));
            if (ILpToken(LpToken).token0() == _token) {
                (
                    _customTokenReserve,
                    _busdTokenReserve,
                    _blockTimestampLast
                ) = ILpToken(LpToken).getReserves();
                value_ = IRouter(Router).quote(
                    _amount,
                    _customTokenReserve,
                    _busdTokenReserve
                );
                return super.valueOf(DAI, value_);
            } else {
                (
                    _busdTokenReserve,
                    _customTokenReserve,
                    _blockTimestampLast
                ) = ILpToken(LpToken).getReserves();
                value_ = IRouter(Router).quote(
                    _amount,
                    _customTokenReserve,
                    _busdTokenReserve
                );
                return super.valueOf(DAI, value_);
            }
        } else {
            return super.valueOf(_token, _amount);
        }
    }

    function settings(
        MANAGING _managing,
        address _address,
        address _calculator
    ) external onlyOwner returns (bool) {
        require(_address != address(0));
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            require(!isReserveDepositor[_address]);
            reserveDepositors.push(_address);
            isReserveDepositor[_address] = true;
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            require(!isReserveSpender[_address]);
            reserveSpenders.push(_address);
            isReserveSpender[_address] = true;
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            require(!isReserveToken[_address]);
            reserveTokens.push(_address);
            isReserveToken[_address] = true;
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            require(!isReserveManager[_address]);
            reserveManagers.push(_address);
            isReserveManager[_address] = true;
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            require(!isLiquidityDepositor[_address]);
            liquidityDepositors.push(_address);
            isLiquidityDepositor[_address] = true;
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            require(!isLiquidityToken[_address]);
            bondCalculator = _calculator;
            liquidityTokens.push(_address);
            isLiquidityToken[_address] = true;
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            require(!isLiquidityManager[_address]);
            liquidityManagers.push(_address);
            isLiquidityManager[_address] = true;
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 7
            require(!isRewardManager[_address]);
            rewardManagers.push(_address);
            isRewardManager[_address] = true;
        } else if (_managing == MANAGING.SOHM) {
            // 8
            sOHM = _address;
        } else if (_managing == MANAGING.CUSTOMTOKENDEPOSITOR) {
            // 9
            require(!isCustomDepositor[_address]);
            customDepositors.push(_address);
            isCustomDepositor[_address] = true;
        } else if (_managing == MANAGING.CUSTOMTOKEN) {
            // 10
            require(!isCustomToken[_address]);
            customTokens.push(_address);
            isCustomToken[_address] = true;
        } else if (_managing == MANAGING.CUSTOMTOKENSPENDER) {
            // 11
            require(!isCustomSpender[_address]);
            customSpenders.push(_address);
            isCustomSpender[_address] = true;
        } else return false;
        emit ChangeQueued(_managing, _address);
        return true;
    }
}