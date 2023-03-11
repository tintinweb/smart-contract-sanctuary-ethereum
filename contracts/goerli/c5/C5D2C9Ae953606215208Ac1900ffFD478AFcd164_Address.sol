/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^ 0.6.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >= 0.6.4;

interface IBEP20 {
    function totalSupply() external view returns(uint256);

function decimals() external view returns(uint8);

function symbol() external view returns(string memory);

function name() external view returns(string memory);

function getOwner() external view returns(address);

function balanceOf(address account) external view returns(uint256);

function transfer(address recipient, uint256 amount)
external
returns(bool);

function allowance(address _owner, address spender)
external
view
returns(uint256);

function approve(address spender, uint256 amount) external returns(bool);

function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^ 0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns(bool) {
  
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size:= extcodesize(account)
        }
        return size > 0;
    }
  function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount } ("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
    internal
    returns(bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns(bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns(bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns(bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns(bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue } (
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size:= mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/libs/SafeBEP20.sol

pragma solidity >= 0.6.0 < 0.8.0;

library SafeBEP20 {
    using SafeMath for uint256;
        using Address for address;

            function safeTransfer(
                IBEP20 token,
                address to,
                uint256 value
            ) internal {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transfer.selector, to, value)
            );
        }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
        value
    );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
        value,
        "SafeBEP20: decreased allowance below zero"
    );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
        data,
        "SafeBEP20: low-level call failed"
    );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}



pragma solidity >= 0.6.0 < 0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^ 0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns(address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^ 0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/BEP20.sol

// SPDX-License-Identifier: MIT

pragma solidity >= 0.4.0;

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

        mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns(address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view override returns(uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
    public
    override
    returns(bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    override
    returns(uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    override
    returns(bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns(bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns(bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns(bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer { }

    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns(bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address public _owner;

    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

// File: contracts/Operon.sol

pragma solidity 0.6.12;

contract Test is ContextUpgradeable, OwnableUpgradeable {

    using SafeMath for uint256;
        using SafeBEP20 for IBEP20;
            struct UserStruct {
            bool isExist;
            uint256 id;
            uint levelIncomeEligible;
            uint256 referrerID;
            uint256 investmentAmount;
            uint256 earnedAmount;
            uint256 levelIncome;
            uint256 globalPoolIncome;
            uint256 referralCount;
            uint256 referralIncome;
            uint256 teamVolume;
            uint256 investmentDate;
            uint256 referupto;
            address[] referrals;
            uint256 levelgainlastDate;
        }
    mapping(address => UserStruct) public users;
    mapping(uint256 => address) public userList;
    mapping(address => bool) public isGlobalPoolEligible;
    mapping(address => uint256) public totalGainAmount;
    address[] public globalPoolAddress;
    address public externalAddress;
    IBEP20 public BusdAddress;
    uint256 public totalParticipants;
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public referralPercent; // 1 means 1000; So 7%
    uint256 public roiPercent;  // 1 means 1000; So 1.5%
    uint256 public globalPoolPercent; // 1 means 1000; So 1%
    uint256 public tradeAmount; // 29.5
    uint256 public earnLimit;
    uint256 public globalVolume;
    mapping(uint256 => uint256) public LEVEL_INCOME;
    address public ownerAddress;
    uint256 public currUserID;
    uint256 public globalPoolShare;
    uint256 public minWithdrawAmount;
    mapping(address => uint256) public levelTotalgained;
    uint256 public reinvestExternalAmount;
    uint256 public minReinvestment;
    mapping (address => bool) public claimBlockAddress;
    constructor() public { }
    function initialize(address _ownerAddress, address _externalAddress) public initializer {
        externalAddress = _externalAddress;
        BusdAddress = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        ownerAddress = _ownerAddress;
        LEVEL_INCOME[1] = 1000; // 1%
        LEVEL_INCOME[2] = 500;  // 0.5%
        LEVEL_INCOME[3] = 250;  // 0.25%
        LEVEL_INCOME[4] = 200;  // 0.20%
        LEVEL_INCOME[5] = 200;  // 0.20%
        LEVEL_INCOME[6] = 200;  // 0.20%
        LEVEL_INCOME[7] = 150;  // 0.15%
        UserStruct memory userinfo;
        currUserID = 1000000;
        userinfo = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            levelIncome: 0,
            levelIncomeEligible: 7,
            investmentAmount: 0,
            earnedAmount: 0,
            referralCount: 0,
            teamVolume: 0,
            referralIncome: 0,
            globalPoolIncome: 0,
            investmentDate: block.timestamp,
            referupto: 0,
            referrals: new address[](0),
            levelgainlastDate: block.timestamp
        });
        users[ownerAddress] = userinfo;
        userList[currUserID] = ownerAddress;
        totalParticipants++;

        minInvestment = 50 * 1e18;
        maxInvestment = 100000 * 1e18;
        referralPercent = 7000;
        roiPercent = 150;
        globalPoolPercent = 1000;
        tradeAmount = 29500;
        earnLimit = 200;
        globalVolume = 120000 * 1e18;
        minWithdrawAmount = 10 * 1e18;
        __Ownable_init();
    }

    function random(uint256 number) public view returns(uint256) {
        return
        uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender
                )
            )
        ) % number;
    }

    function regUser(address _referrer, uint256 _amount) public {
        require(!users[msg.sender].isExist, "User exist");
        require(users[_referrer].isExist, "Refferrar not in the plan");
        require(_amount >= minInvestment, "Investment is low");
        UserStruct memory userinfo;
        uint256 referID = users[_referrer].id;
        users[_referrer].referralCount++;
        if (users[_referrer].referralCount == 6 && _referrer != ownerAddress) {
            users[_referrer].levelIncomeEligible = 1;
        } else if (users[_referrer].referralCount == 15 && _referrer != ownerAddress) {
            users[_referrer].levelIncomeEligible = 4;
        }
        totalParticipants++;
        users[_referrer].referrals.push(msg.sender);
        BusdAddress.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 externalAmt = _amount.mul(tradeAmount).div(100000);
        BusdAddress.safeTransfer(externalAddress, externalAmt);
        //direct Referral
        if (checkIsEarn(_referrer)) {
            uint256 directReferAmount = _amount.mul(referralPercent).div(100000);
            uint256 roiAmountEarnings = checkRoiUpto(_referrer);
            uint256 newEarnings = roiAmountEarnings.add(users[_referrer].referupto).add(users[_referrer].earnedAmount).add(directReferAmount);
            uint256 maxlimit = users[_referrer].investmentAmount.mul(earnLimit).div(100);
            if (newEarnings >= maxlimit && _referrer != ownerAddress) {
                if (roiAmountEarnings >= maxlimit) {
                    directReferAmount = 0;
                } else {
                    directReferAmount = maxlimit.sub(roiAmountEarnings).sub(users[_referrer].earnedAmount).sub(users[_referrer].referupto);
                }
            }
            if (directReferAmount > 0) {
                BusdAddress.safeTransfer(_referrer, directReferAmount);
                users[_referrer].referralIncome += directReferAmount;
                users[_referrer].referupto += directReferAmount;
                totalGainAmount[_referrer] += directReferAmount;
            }
        }
        uint256 globalShare = _amount.mul(globalPoolPercent).div(100000);
        globalPoolShare += globalShare;
        uint256 _referid = random(1000000);

        if(users[userList[_referid]].isExist){
          _referid = random(10000000);
        }

        userinfo = UserStruct({
            isExist: true,
            id: _referid,
            referrerID: referID,
            levelIncome: 0,
            investmentAmount: _amount,
            levelIncomeEligible: 0,
            earnedAmount: 0,
            referralCount: 0,
            teamVolume: 0,
            referralIncome: 0,
            globalPoolIncome: 0,
            referupto: 0,
            investmentDate: block.timestamp,
            referrals: new address[](0),
            levelgainlastDate: block.timestamp
        });
        userList[_referid] = msg.sender;
        users[msg.sender] = userinfo;



        updateTeamVolumeAndPaylevel(_referrer, _amount, 1);



    }

    function reInvest(uint256 _amount) public {
        require(users[msg.sender].isExist, "User not exist");
        require(_amount >= minReinvestment, "Investment is low");

           uint256 uptoroi = checkRoiUpto(msg.sender);
           uint256 levelNewEarning = checkLevelUpto(msg.sender);
           uint256 totalearned = uptoroi.add(users[msg.sender].earnedAmount).add(users[msg.sender].referupto).add(levelNewEarning);

           users[msg.sender].earnedAmount += uptoroi.add(levelNewEarning);
           uint256 maxlimit = users[msg.sender].investmentAmount.mul(earnLimit).div(100);

        if (totalearned >= maxlimit) {
            users[msg.sender].investmentAmount = 0;
            users[msg.sender].referupto = 0;
            users[msg.sender].levelIncome = 0;
        }

        BusdAddress.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 externalAmt = _amount.mul(reinvestExternalAmount).div(100000);
        BusdAddress.safeTransfer(externalAddress, externalAmt);
        if(users[msg.sender].earnedAmount > 0){
          BusdAddress.safeTransfer(msg.sender, users[msg.sender].earnedAmount);
        }
        users[msg.sender].referupto += users[msg.sender].earnedAmount;
        totalGainAmount[msg.sender] += users[msg.sender].earnedAmount;
        users[msg.sender].earnedAmount = 0;
        users[msg.sender].investmentAmount += _amount;
           address parentAddress = userList[users[msg.sender].referrerID];
        updateTeamVolumeAndPaylevel(parentAddress, _amount, 1);
        users[msg.sender].investmentDate = block.timestamp;
        levelTotalgained[msg.sender] = 0;
        users[msg.sender].levelgainlastDate = block.timestamp;


    }


    function claimOrRetopop(bool isClaim) public {
        require(isClaim, "Only Claim");
        require(!claimBlockAddress[msg.sender],"Claim Disabled by admin");

        require(users[msg.sender].isExist, "User not exist");
        uint256 roiAmountEarnings = checkRoiUpto(msg.sender);
        uint256 levelNewEarning = checkLevelUpto(msg.sender);
        uint256 totalearned = roiAmountEarnings.add(users[msg.sender].earnedAmount).add(levelNewEarning);
        users[msg.sender].earnedAmount = totalearned;
        uint256 maxlimit = users[msg.sender].investmentAmount.mul(earnLimit).div(100);
        if (totalearned.add(users[msg.sender].referupto) >= maxlimit && msg.sender != ownerAddress) {
            users[msg.sender].earnedAmount = maxlimit - users[msg.sender].referupto;
            if (isClaim) {
                require(users[msg.sender].earnedAmount >= minWithdrawAmount, "User should reach minimum withdraw");
                BusdAddress.safeTransfer(msg.sender, users[msg.sender].earnedAmount);
                totalGainAmount[msg.sender] += users[msg.sender].earnedAmount;
                users[msg.sender].investmentAmount = 0;
                users[msg.sender].referupto = 0;
            } else {
                users[msg.sender].investmentAmount = users[msg.sender].earnedAmount;
                uint256 externalAmt = users[msg.sender].earnedAmount.mul(reinvestExternalAmount).div(100000);
                BusdAddress.safeTransfer(externalAddress, externalAmt);
                users[msg.sender].referupto = 0;
            }
            users[msg.sender].levelIncome = 0;
        } else {
            if (isClaim) {
                require(users[msg.sender].earnedAmount >= minWithdrawAmount, "User should reach minimum withdraw");
                BusdAddress.safeTransfer(msg.sender, users[msg.sender].earnedAmount);
                totalGainAmount[msg.sender] += users[msg.sender].earnedAmount;
                users[msg.sender].referupto += users[msg.sender].earnedAmount;

            } else {
                users[msg.sender].investmentAmount += users[msg.sender].earnedAmount;
                uint256 externalAmt = users[msg.sender].earnedAmount.mul(reinvestExternalAmount).div(100000);
                BusdAddress.safeTransfer(externalAddress, externalAmt);
                users[msg.sender].referupto += users[msg.sender].earnedAmount;
            }
            users[msg.sender].investmentDate = block.timestamp;
        }
        users[msg.sender].earnedAmount = 0;
        levelTotalgained[msg.sender] = 0;
        users[msg.sender].levelgainlastDate = block.timestamp;
    }

    function updateTeamVolumeAndPaylevel(address upliner, uint256 _amount, uint _cnt) internal {
        if (upliner != 0x0000000000000000000000000000000000000000) {
            users[upliner].teamVolume += _amount;
            if (users[upliner].teamVolume > globalVolume && !isGlobalPoolEligible[upliner]) {
                isGlobalPoolEligible[upliner] = true;
                globalPoolAddress.push(upliner);
            }
            if (_cnt < 8) {
                uint countCheck = 0;
                if (users[upliner].levelIncomeEligible < 7) {
                    if (users[upliner].referralCount > 0) {
                        for (uint i = 0; i < users[upliner].referralCount; i++) {
                        uint256 childCount = users[users[upliner].referrals[i]].referralCount;
                            if (childCount >= 15) {
                                countCheck++;
                            }
                        }
                    }
                }
                if (countCheck >= 3) {
                    users[upliner].levelIncomeEligible = 7;
                }

                if (users[upliner].levelIncomeEligible >= _cnt && checkIsEarn(upliner)) {
                     uint256 sendAmount = _amount.mul(LEVEL_INCOME[_cnt]).div(100000); // New
                    uint256 lastinvstdate = users[upliner].levelgainlastDate;
                    if (lastinvstdate == 0) {
                        lastinvstdate = users[upliner].investmentDate;
                    }

                    uint checkdiff = checkdatediff(lastinvstdate, block.timestamp);
                    if (checkdiff < 1) {
                        users[upliner].levelIncome += sendAmount;
                    } else {
                        uint256 perdaySec = 86400;
                        levelTotalgained[upliner] += users[upliner].levelIncome.mul(checkdiff);
                        users[upliner].levelgainlastDate = lastinvstdate.add(perdaySec.mul(checkdiff));
                        users[upliner].levelIncome += sendAmount;
                    }
                }
            }
            address nextParent = userList[users[upliner].referrerID];
            _cnt++;
            updateTeamVolumeAndPaylevel(nextParent, _amount, _cnt);
        }
    }

    function checkIsEarn(address _user) public view returns(bool) {
        uint256 startDate = users[_user].investmentDate;
        uint256 endDate = block.timestamp;
        uint diff = (endDate - startDate) / 60 / 60 / 24;
        uint256 uptoroi = diff.mul(users[_user].investmentAmount.mul(roiPercent).div(100000));
        uint256 totalearned = uptoroi.add(users[_user].earnedAmount).add(users[_user].referupto);
        //add level income daily
         uint256 lastinvstdate = users[_user].levelgainlastDate;
        if (lastinvstdate == 0) {
            lastinvstdate = users[_user].investmentDate;
        }
        uint checkdiff = checkdatediff(lastinvstdate, block.timestamp);
        uint256 levelNewEarning = 0;
        if (checkdiff > 0) {
            levelNewEarning = levelTotalgained[_user] + users[_user].levelIncome.mul(checkdiff);
        }
        if (totalearned.add(levelNewEarning) >= users[_user].investmentAmount.mul(earnLimit).div(100) && _user != ownerAddress) {
            return false;
        } else {
            return true;
        }
    }

    function checkRoiUpto(address _user) public view returns(uint256){
        uint256 startDate = users[_user].investmentDate;
        uint256 endDate = block.timestamp;
        uint diff = (endDate - startDate) / 60 / 60 / 24;
        uint256 uptoroi = diff.mul(users[_user].investmentAmount.mul(roiPercent).div(100000));
        return uptoroi;
    }


    function ClaimglobalPoolIncome() public {
       uint256 globalincome = users[msg.sender].globalPoolIncome;
        if (globalincome > 0) {
            BusdAddress.safeTransfer(msg.sender, globalincome);
            users[msg.sender].globalPoolIncome = 0;
        }
    }

    function globalPoolDistribution(uint256 _amount) public onlyOwner {
        if (globalPoolAddress.length > 0 && _amount > 0) {
            for (uint i = 0; i < globalPoolAddress.length; i++) {
            uint256 perUserAmount = _amount / globalPoolAddress.length;
                users[globalPoolAddress[i]].globalPoolIncome += perUserAmount;
            }
            globalPoolShare = 0;
        }
    }

    function getAllReferralAddress(address _user) public view returns(address[] memory){
        return users[_user].referrals;
    }

    function getAllglobalPoolAddress() public view returns(address[] memory){
        return globalPoolAddress;
    }

    function getUserAddress(uint256 _userID) public view returns(address){
        return userList[_userID];
    }

    function updateGlobalPool(uint256 _val) public onlyOwner {
        globalVolume = _val;
    }

    function safeWithdraw(uint256 _amount, address _address) public onlyOwner {
        BusdAddress.safeTransfer(_address, _amount);
    }

    function setminWithdrawAmount(uint256 _amount) public onlyOwner {
        minWithdrawAmount = _amount * 1e18;
    }

    function setminInvestment(uint256 _amount) public onlyOwner {
        minInvestment = _amount * 1e18;
    }
    function setreferralPercent(uint256 _percent) public onlyOwner {
        referralPercent = _percent;
    }

    function updateearnLimit(uint256 _earnLimit) public onlyOwner {
        earnLimit = _earnLimit;
    }
    function updateRoiPercentage(uint256 _percentage) public onlyOwner {
        roiPercent = _percentage;
    }

    function checkdatediff(uint256 startDate, uint256 endDate) internal pure returns(uint){
        uint diff = (endDate - startDate) / 60 / 60 / 24;
        return diff;
    }

    function checkLevelUpto(address _user) public view returns(uint256){
        uint256 lastinvstdate = users[_user].levelgainlastDate;
        if (lastinvstdate == 0) {
            lastinvstdate = users[_user].investmentDate;
        }
        uint256 startDate = lastinvstdate;
        uint256 endDate = block.timestamp;
        uint diff = (endDate - startDate) / 60 / 60 / 24;
        uint256 levelNewEarning;
        if (diff > 0) {
            levelNewEarning = levelTotalgained[_user] + users[_user].levelIncome.mul(diff);
        } else {
            levelNewEarning = levelTotalgained[_user];
        }
        return levelNewEarning;
    }

    function checkAvailableUpto(address _user) public view returns(uint256){
         uint256 roiAmountEarnings = checkRoiUpto(_user);
         uint256 levelNewEarning = checkLevelUpto(_user);
         uint256 totalearned = roiAmountEarnings.add(users[_user].earnedAmount).add(levelNewEarning);
         uint256 maxlimit = users[_user].investmentAmount.mul(earnLimit).div(100);
         uint256 uptoEarn;
        if (totalearned.add(users[_user].referupto) >= maxlimit && _user != ownerAddress) {
            uptoEarn = maxlimit - users[_user].referupto;
        } else {
            uptoEarn = totalearned;
        }
        return uptoEarn;
    }

    function setminReInvestment(uint256 amount) public onlyOwner {
        minReinvestment = amount * 1e18;
    }

    function addclaimBlockAddress(address[] memory _accounts) public onlyOwner {
       for(uint i=0; i< _accounts.length; i++){
          claimBlockAddress[_accounts[i]] = true;
       }
     }

     function removeclaimBlockAddress(address _accounts) public onlyOwner {
         claimBlockAddress[_accounts] = false;
     }
}