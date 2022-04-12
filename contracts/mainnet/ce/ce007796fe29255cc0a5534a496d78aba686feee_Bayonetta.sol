/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
Lore, rules and info: https://ipfs.8bitcrypto.org/ipfs/QmYz5FANBtEgpFGgSXdvJaJGd2DjhiyABHQEzfYFM26S1A
 _______       __       ___  ___  ______    _____  ___    _______  ___________  ___________   __      
|   _  "\     /""\     |"  \/"  |/    " \  (\"   \|"  \  /"     "|("     _   ")("     _   ") /""\     
(. |_)  :)   /    \     \   \  /// ____  \ |.\\   \    |(: ______) )__/  \\__/  )__/  \\__/ /    \    
|:     \/   /' /\  \     \\  \//  /    ) :)|: \.   \\  | \/    |      \\_ /        \\_ /   /' /\  \   
(|  _  \\  //  __'  \    /   /(: (____/ // |.  \    \. | // ___)_     |.  |        |.  |  //  __'  \  
|: |_)  :)/   /  \\  \  /   /  \        /  |    \    \ |(:      "|    \:  |        \:  | /   /  \\  \ 
(_______/(___/    \___)|___/    \"_____/    \___|\____\) \_______)     \__|         \__|(___/    \___)

Community owned deflationary lore-backed evolutionary token
                                                                                                      
         _______            _________________           _______ _______ _       _______ 
|\     /(  ___  |\     /|   \__   __\__   __/  |\     /(  ___  (  ____ | \    /(  ____ \
| )   ( | (   ) | )   ( |      ) (     ) (     | )   ( | (   ) | (    )|  \  / | (    \/
| (___) | |   | | | _ | |      | |     | |     | | _ | | |   | | (____)|  (_/ /| (_____ 
|  ___  | |   | | |( )| |      | |     | |     | |( )| | |   | |     __|   _ ( (_____  )
| (   ) | |   | | || || |      | |     | |     | || || | |   | | (\ (  |  ( \ \      ) |
| )   ( | (___) | () () |   ___) (___  | |     | () () | (___) | ) \ \_|  /  \ /\____) |
|/     \(_______(_______)   \_______/  )_(     (_______(_______|/   \__|_/    \\_______)
                                                                                         
Welcome to Bayonetta, traveler.

You stumbled across a secret gem, while wandering in the metaverse.
Please, take a sit.

This token starts like a newborn: no Telegram, no Website, no Marketing.
But that's how life is born.
You are invited to be the first, or to be a pioneer, by CREATING or JOINING the telegram group named:
@bayonettatokenofficial
Only this group will be considered official by the Creators.
The Creators, in disguise, will join the group shortly after it will be created.
They will look at you, at your actios, at Bayonetta's path.

To ensure trust and security, the Creators decided to lock the LP forever. You are free to check LP holders
to see only Bayonetta contract has and produces it. 
More, all the tokens are in liquidity or burned.
Yes, Bayonetta has its decay, included in the tokenomics.

BUY TAX: 3% - the Creators set the tax as low as possible to keep growing liquidity
(2% Bayonetta Treasure - 1% Liquidity)
SELL TAX: 5% - Sellers are welcomed, but they need to repay the community
(2% Bayonetta Treasure - 2% Liquidity - 1% Burn)

The Creators will look at the efforts of the Travelers: based on on chain, social and marketing work, the
Creators will contact regularly the most active or prominent Travelers to grant them the right prize for 
their efforts.

This is Bayonetta.
Let the dance begin.

 _       _______ _______ _______ 
( \     (  ___  (  ____ (  ____ \
| (     | (   ) | (    )| (    \/
| |     | |   | | (____)| (__    
| |     | |   | |     __|  __)   
| |     | |   | | (\ (  | (      
| (____/| (___) | ) \ \_| (____/\
(_______(_______|/   \__(_______/
                                 
Decades ago, crypto communities ruled the crypto-world. 
These rule breakers and dissidents came in hordes demanding 
complete power of the new resources being produced. Many from popular 
cryptocurrencies such as Ethereum, Hyperledger and Raiblocks flocked 
to the Metaverse virtual reality world, the first iteration of smart contract technologies. 
agi
There they created socials for tokens: collectibles that digitized 
he equity formerly assigned to humans in cooperatives and municipalities, 
riving global economic growth for an exciting short period of time.

Times have changed and a new generation of private organizations has taken over. Kidnapping all decentralized applications on their centrally controlled, DRM laden deserts and reducing people all over the world close back to a miser, forgotten by technology once again
This is how life was back in 2022, when Bayonetta rose from the past to return the control to the community.

*/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = msg.sender;
        _owner = 0xb899E794e3d0E1c564e3C6Db4ab174DB50ca817B;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




library Address {

    function isContract(address account) internal view returns (bool) {
            uint256 size;
           assembly { size := extcodesize(account) }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

           (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

           (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

           (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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
}

library EnumerableSet {

    struct Set {
           bytes32[] _values;

              mapping (bytes32 => uint256) _indexes;
    }


    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
                          set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }


    function _remove(Set storage set, bytes32 value) private returns (bool) {
           uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
                            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

                     bytes32 lastvalue = set._values[lastIndex];

                   set._values[toDeleteIndex] = lastvalue;
                   set._indexes[lastvalue] = valueIndex;

                   set._values.pop();

                   delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }


    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }


    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }


    struct Bytes32Set {
        Set _inner;
    }


    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }


    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }


    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }


    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }


    struct AddressSet {
        Set _inner;
    }


    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }


    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }


    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    struct UintSet {
        Set _inner;
    }


    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }


    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }


    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }


    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


contract Bayonetta is IERC20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) public _sellLock;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _isFree;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => AddressFee) public _addressFees;


    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromSellLock;


    string public constant _name = 'Bayonetta (Info in the Contract)';
    string public constant _symbol = 'BAYO';
    uint8 public constant _decimals = 18;
    uint256 public constant MaxSupply= 1 * 10**6 * 10**_decimals;
    uint256 public InitialSupply= MaxSupply/2;

    uint256 swapLimit = 5 * 10**4 * 10**_decimals;
    bool isSwapPegged = true;
    bool noTax = false;


    uint16 public  BuyLimitDivider=1;
    uint16 public   BalanceLimitDivider=1;
    uint16 public  SellLimitDivider=1;

    uint16 public  MaxSellLockTime= 10 seconds;

    mapping (address => bool) isAuth;

    address public constant UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;
    address public devAddress;

    uint256 public _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
    uint256 public  buyLimit = _circulatingSupply;


    uint8 public _buyTax;
    uint8 public _sellTax;
    uint8 public _transferTax;

    uint8 public _liquidityTax;
    uint8 public _marketingTax;
    uint8 public _burnTax;

    uint8 public _liquidityTax_buy;
    uint8 public _marketingTax_buy;
    uint8 public _burnTax_buy;

    uint8 public _liquidityTax_sell;
    uint8 public _marketingTax_sell;
    uint8 public _burnTax_sell;

    struct AddressFee {
        bool enable;
        uint8 _transferTax;
        uint8 _buyTax;
        uint8 _sellTax;
    }

    bool isTokenSwapManual = false;
    bool public antisniper = true;

    address public _UniswapPairAddress;
    IUniswapRouter02 public  _UniswapRouter;


    modifier onlyAuth() {
        require(_isAuth(msg.sender), "Caller not in Auth");
        _;
    }

    modifier onlyDev() {
        require(devAddress==msg.sender, "Caller not dev");
        _;
    }

    function _isAuth(address addr) private view returns (bool){
        return addr==owner()||isAuth[addr];
    }


    constructor () {
        uint256 deployerBalance=_circulatingSupply;
        devAddress = msg.sender;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        //uint256 injectBalance=_circulatingSupply-deployerBalance;
        //_balances[address(this)]=injectBalance;
        //emit Transfer(address(0), address(this),injectBalance);
        _UniswapRouter = IUniswapRouter02(UniswapRouter);

        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory()).createPair(address(this), _UniswapRouter.WETH());

        balanceLimit=_circulatingSupply/BalanceLimitDivider;
        sellLimit=_circulatingSupply/SellLimitDivider;
        buyLimit=_circulatingSupply/BuyLimitDivider;

        isAuth[msg.sender] = true;
        sellLockTime=2 seconds;

        _buyTax=3;
        _sellTax=5;
        _transferTax=3;

        _liquidityTax_buy=30;
        _marketingTax_buy=65;
        _burnTax_buy=5;

        _liquidityTax_sell=20;
        _marketingTax_sell=60;
        _burnTax_sell=20;

        _excluded.add(msg.sender);
        _excludedFromSellLock.add(UniswapRouter);
        _excludedFromSellLock.add(_UniswapPairAddress);
        _excludedFromSellLock.add(address(this));
    }


    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Uh oh, someone's been naughty");

        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient) || isAuth[sender] || isAuth[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == _UniswapPairAddress && recipient == UniswapRouter)
        || (recipient == _UniswapPairAddress && sender == UniswapRouter));
        bool taxesOff = noTax;

        if(isContractTransfer || isLiquidityTransfer || isExcluded || taxesOff){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!tradingEnabled) {
                if (sender != owner() && recipient != owner()) {
                    if (antisniper) {
                        emit Transfer(sender,recipient,0);
                        return;
                    }
                    else {
                        require(tradingEnabled,"trading not yet enabled");
                    }
                }
            }

            bool isBuy=sender==_UniswapPairAddress|| sender == UniswapRouter;
            bool isSell=recipient==_UniswapPairAddress|| recipient == UniswapRouter;
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);


        }
    }


    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");


        swapLimit = sellLimit/2;

        uint8 tax;
        if(isSell){
            _marketingTax = _marketingTax_sell;
            _burnTax = _burnTax_sell;
            _liquidityTax = _liquidityTax_sell;

            if(!_excludedFromSellLock.contains(sender)){
                           require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                           _sellLock[sender]=block.timestamp+sellLockTime;
            }

            require(amount<=sellLimit,"Dump protection");
            if (_addressFees[sender].enable){
                _sellTax = _addressFees[sender]._sellTax;
            }
            tax=_sellTax;

        } else if(isBuy){
            _marketingTax = _marketingTax_buy;
            _burnTax = _burnTax_buy;
            _liquidityTax = _liquidityTax_buy;
            if(!_isFree[recipient]){
                require(recipientBalance+amount<=balanceLimit,"whale protection");
            }
            require(amount<=buyLimit, "whale protection");
            if (_addressFees[recipient].enable){
                _buyTax = _addressFees[recipient]._buyTax;
            }
            tax=_buyTax;


        } else {
            _marketingTax = _marketingTax_buy;
            _burnTax = _burnTax_buy;
            _liquidityTax = _liquidityTax_buy;
            if(!_isFree[recipient]){
                require(recipientBalance+amount<=balanceLimit,"whale protection");
            }
            if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            if (_addressFees[sender].enable){
                _transferTax = _addressFees[sender]._transferTax;
            }
            tax=_transferTax;

        }
                 if((sender!=_UniswapPairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier))
            _swapContractToken(amount);
            uint256 contractToken = _calculateFee(amount, tax, _marketingTax+_liquidityTax+_burnTax);
            uint256 taxedAmount = amount-(contractToken);

           _removeToken(sender,amount);

           _balances[address(this)] += contractToken;

           _addToken(recipient, taxedAmount);

        emit Transfer(sender,recipient,taxedAmount);



    }

    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
           _removeToken(sender,amount);
           _addToken(recipient, amount);

        emit Transfer(sender,recipient,amount);

    }

    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }


    function _addToken(address addr, uint256 amount) private {
           uint256 newAmount=_balances[addr]+amount;
        _balances[addr]=newAmount;

    }



    function _removeToken(address addr, uint256 amount) private {
           uint256 newAmount=_balances[addr]-amount;
        _balances[addr]=newAmount;
    }


    bool private _isTokenSwaping;

    uint256 public totalTokenSwapGenerated;

    uint256 public totalPayouts;



    uint256 public marketingBalance;

    function _distributeFeesETH(uint256 ETHamount) private {
        uint8 marketingShare = (_marketingTax*100)/(_marketingTax+_burnTax);
        uint8 burnShare = 100 - marketingShare;
        uint256 marketingSplit = (ETHamount * marketingShare)/100;
        uint256 burnSplit = (ETHamount * burnShare)/100;

        marketingBalance+=marketingSplit;
        _balances[_UniswapPairAddress]-=burnSplit;
        _circulatingSupply-=burnSplit;
        emit Transfer(_UniswapPairAddress, 0x000000000000000000000000000000000000dEaD, burnSplit);

    }

    uint256 public totalLPETH;

    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken(uint256 totalMax) private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_marketingTax;
        uint256 tokenToSwap=swapLimit;
        if(tokenToSwap > totalMax) {
            if(isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= (tokenToSwap*_marketingTax)/totalTax;

        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqETHToken=tokenForLiquidity-liqToken;

        uint256 swapToken=liqETHToken+tokenForMarketing;
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH=(address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        uint256 generatedETH=(address(this).balance - initialETHBalance);
        _distributeFeesETH(generatedETH);
    }

    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_UniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapRouter.WETH();

        _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        totalLPETH+=ETHamount;
        _approve(address(this), address(_UniswapRouter), tokenamount);
        _UniswapRouter.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @notice Utilities


    function destroy(uint256 amount) private {
        require(_balances[address(this)] >= amount);
        _balances[address(this)] -= amount;
        _circulatingSupply -= amount;
        emit Transfer(address(this), Dead, amount);
    }

    function ______LORE_AND_INFO() public pure returns(string memory) {
        return("https://ipfs.8bitcrypto.org/ipfs/QmYz5FANBtEgpFGgSXdvJaJGd2DjhiyABHQEzfYFM26S1A");
    }

    function Control_getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function Control_getTaxes() public view returns(uint256 devTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_liquidityTax,_marketingTax,_buyTax,_sellTax,_transferTax);
    }

    function Control_getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
        uint256 lockTime=_sellLock[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }
    function Control_getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }

    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion;


    function Control_SetPeggedSwap(bool isPegged) public onlyAuth {
        isSwapPegged = isPegged;
    }

    function Control_SetMaxSwap(uint256 max) public onlyAuth {
        swapLimit = max;
    }


    /// @notice ACL Functions

    function Access_SetAuth(address addy, bool booly) public onlyAuth {
        isAuth[addy] = booly;
    }

    function Access_ExcludeAccountFromFees(address account) public onlyAuth {
        _excluded.add(account);
    }
    function Access_IncludeAccountToFees(address account) public onlyAuth {
        _excluded.remove(account);
    }

    function Access_ExcludeAccountFromSellLock(address account) public onlyAuth {
        _excludedFromSellLock.add(account);
    }
    function Access_IncludeAccountToSellLock(address account) public onlyAuth {
        _excludedFromSellLock.remove(account);
    }

    function Auth_WithdrawMarketingETH() public onlyAuth{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        address sender = 0xb899E794e3d0E1c564e3C6Db4ab174DB50ca817B;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function Control_SwitchManualETHConversion(bool manual) public onlyAuth{
        manualConversion=manual;
    }

    function Control_DisableSellLock(bool disabled) public onlyAuth{
        sellLockDisabled=disabled;
    }

    function UTILIY_SetSellLockTime(uint256 sellLockSeconds)public onlyAuth{
        sellLockTime=sellLockSeconds;
    }

    function UTILITY_MintContract(uint amount) public onlyOwner {
        address receiver = address(this);
        require (_circulatingSupply + amount <= MaxSupply);
        _circulatingSupply += amount;
        _balances[receiver] += amount;
        emit Transfer(Dead, receiver, amount);
    }


    function Control_SetTaxes(
        uint8 burnTaxes_buy, uint8 liquidityTaxes_buy, uint8 marketingTaxes_buy,
        uint8 burnTaxes_sell, uint8 liquidityTaxes_sell, uint8 marketingTaxes_sell,
        uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyAuth{

        require(buyTax <= 15, "Taxes are too high");
        require(sellTax <= 15, "Taxes are too high");
        require(transferTax <= 15, "Taxes are too high");
        uint8 totalTax_buy=burnTaxes_buy+liquidityTaxes_buy+marketingTaxes_buy;
        require(totalTax_buy==100, "liq+marketing needs to equal 100%");
        uint8 totalTax_sell=burnTaxes_sell+liquidityTaxes_sell+marketingTaxes_sell;
        require(totalTax_sell==100, "liq+marketing needs to equal 100%");
        _burnTax_buy = burnTaxes_buy;
        _liquidityTax_buy=liquidityTaxes_buy;
        _marketingTax_buy=marketingTaxes_buy;

        _burnTax_sell = burnTaxes_sell;
        _liquidityTax_sell=liquidityTaxes_sell;
        _marketingTax_sell=marketingTaxes_sell;

        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
    }

    function Control_ManualGenerateTokenSwapBalance(uint256 _qty) public onlyAuth{
        _swapContractToken(_qty * 10**9);
    }


    function Control_UpdateLimits(uint256 newBuyLimit ,uint256 newBalanceLimit, uint256 newSellLimit) public onlyAuth{
        newBuyLimit = newBuyLimit *10**_decimals;
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newSellLimit=newSellLimit*10**_decimals;
        buyLimit = newBuyLimit;
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
    }





    bool public tradingEnabled;
    address private _liquidityTokenAddress;


    function Settings_EnableTrading() public onlyAuth{
        tradingEnabled = true;
    }


    function Settings_LiquidityTokenAddress(address liquidityTokenAddress) public onlyAuth{
        _liquidityTokenAddress=liquidityTokenAddress;
    }

    function UTILITY_RescueTokens(address tknAddress) public onlyAuth {
        IERC20 token = IERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function Control_setContractTokenSwapManual(bool manual) public onlyAuth {
        isTokenSwapManual = manual;
    }

    function CONTROL_blacklistAddress(address account) public onlyOwner {
        _isBlacklisted[account] = true;
    }

    function CONTROL_unBlacklistAddress(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }

    function UTILITY_checkBlacklist(address account) public view onlyOwner returns(bool){
        return _isBlacklisted[account];
    }

    function CONTROL_setFree(address account) public onlyOwner {
        _isFree[account] = true;
    }

    function CONTROL_unSetFree(address account) public onlyOwner {
        _isFree[account] = false;
    }

    function CONTROL_removeAllTaxes(bool taxesonoff) public onlyAuth{
        noTax = taxesonoff;
    }


    function UTILITY_checkFree(address account) public view onlyOwner returns(bool){
        return _isFree[account];
    }


    function setAddressFee(address _address, bool _enable, uint8 _addressBuyTax, uint8 _addressSellTax, uint8 _addressTransferTax) public onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._buyTax = _addressBuyTax;
        _addressFees[_address]._sellTax = _addressSellTax;
        _addressFees[_address]._transferTax = _addressTransferTax;
    }


    receive() external payable {}
    fallback() external payable {}


    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }



    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}