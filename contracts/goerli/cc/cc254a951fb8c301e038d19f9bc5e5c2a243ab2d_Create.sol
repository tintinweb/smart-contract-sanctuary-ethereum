/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context, Pausable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner whenNotPaused {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner)
        public
        virtual
        onlyOwner
        whenNotPaused
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Create is Context, IERC20, IERC20Metadata, Pausable, Ownable {
    using Address for address;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromDexFee;
    mapping(address => bool) public _isIncludedinFee;

    uint256 private totalsupply = 100000000 * 10**18; // intially 550000000000
    string private constant _name = "Indie Creator Token";
    string private constant _symbol = "CREATE";
    uint8 private constant _decimals = 18;
    address public createProductionsWallet;
    address public cryptoTokenWallet;
    address public nftWallet;
    address public shortVideoWallet;
    address public musicWallet;
    address public eventsWallet;
    address public marketingWallet;
    address public staffWageWallet;

    //fee percentages
    uint256 public marketingFee = 150;
    uint256 public staffFee = 150;
    uint256 public cryptoTokenFee = 150;
    uint256 public nftFee = 150;
    uint256 public shortVideoFee = 150;
    uint256 public musicFee = 150;
    uint256 public eventsFee = 150;
    uint256 public createProductionsFee = 150;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    address UNISWAPV2ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public usdccontractaddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public BuyETH = 0xE9462C3f94541154A1C6bD19AAfBC24FeaB0A808;
    address public Platform_donation = 0x048D5408110F493cc983Fe9d4e404d5d4a9Fc2EF;

    bool public enableFee = true;

    bool public createProductionsSwapEnabled = true;
    bool public cryptoTokenSwapEnabled = true;
    bool public nftSwapEnabled = true;
    bool public shortVideoSwapEnabled = true;
    bool public musicSwapEnabled = true;
    bool public eventsSwapEnabled = true;
    bool public marketingSwapEnabled = true;
    bool public staffWageSwapEnabled = true;
    bool public enableplatformfunctions = true;

    uint256 public maxSellLimit = 1000000000 * 10**18;

    uint256 public minimumTokensBeforeSwap = 1000000000 * 10**18;

    event FeeEnabled(bool enableFee);

    event SetMaxTxPercent(uint256 maxPercent);
    event SetTaxFeePercent(uint256 taxFeePercent);

    event SetCreateProductionsFeePercent(uint256 fee);
    event SetCryptoTokenFeePercent(uint256 fee);
    event SetNftFeePercent(uint256 fee);
    event SetShortVideoFeePercent(uint256 fee);
    event SetMusicFeePercent(uint256 fee);
    event SetEventsFeePercent(uint256 fee);
    event SetMarketingFeePercent(uint256 fee);
    event SetStaffFeePercent(uint256 fee);

    event SetMaximumSellLimitUniswap(uint256 sellLimit);
    event SetMinimumTokensBeforeSwap(uint256 minimumTokensBeforeSwap);

    event SetCreateProductionsSwapEnabled(bool enabled);
    event SetCryptoTokenSwapEnabled(bool enabled);
    event SetNftSwapEnabled(bool enabled);
    event SetShortVideoSwapEnabled(bool enabled);
    event SetMusicSwapEnabled(bool enabled);
    event SetEventsSwapEnabled(bool enabled);
    event SetStaffSwapEnabled(bool enabled);
    event SetMarketingSwapEnabled(bool enabled);

    event TokenFromContractTransfered(
        address externalAddress,
        address toAddress,
        uint256 amount
    );
    event ETHFromContractTransferred(uint256 amount);
    event BuyPowerVoteETH(
        uint256 value,
        uint256 VoteId,
        uint256 userId,
        uint256 eventid
    );
    event BuyPowerVoteERC20(
        uint256 value,
        uint256 id,
        address _tokenContract,
        uint256 userId,
        uint256 eventid
    );
    event DonateETH(
        uint256 value,
        uint256 projectId,
        uint256 userId,
        uint256 eventid,
        address _creatorAccount
    );
    event DonateERC20(
        uint256 value,
        uint256 projectId,
        uint256 userId,
        address _tokenContract,
        address _creatorAccount,
        uint256 eventid
    );
    event LogMessage(string message);

    constructor(
        address _createProductionsWallet,
        address _cryptoTokenWallet,
        address _nftWallet,
        address _shortVideoWallet,
        address _musicWallet,
        address _eventsWallet,
        address _marketingWallet,
        address _staffWageWallet
    ) {
        balances[_msgSender()] = totalsupply;
        createProductionsWallet = _createProductionsWallet;
        cryptoTokenWallet = _cryptoTokenWallet;
        nftWallet = _nftWallet;
        shortVideoWallet = _shortVideoWallet;
        musicWallet = _musicWallet;
        eventsWallet = _eventsWallet;
        marketingWallet = _marketingWallet;
        staffWageWallet = _staffWageWallet;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            UNISWAPV2ROUTER
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _isIncludedinFee[uniswapV2Pair] = true;

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        emit Transfer(address(0), _msgSender(), totalsupply);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return totalsupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balances[account]; //added
    }

    function gettotalSwapFee() public view returns (uint256) {
        uint256 total = 0;
        if (createProductionsSwapEnabled)
            total = total + (createProductionsFee);

        if (cryptoTokenSwapEnabled) total = total + (cryptoTokenFee);

        if (nftSwapEnabled) total = total + (nftFee);

        if (shortVideoSwapEnabled) total = total  + (shortVideoFee);

        if (musicSwapEnabled) total = total + (musicFee);

        if (eventsSwapEnabled) total = total + (eventsFee);

        if (marketingSwapEnabled) total = total  + (marketingFee);

        if (staffWageSwapEnabled) total = total  + (staffFee);

        return total;
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    struct Donate {
        uint256 value;
        uint256 projectId;
        uint256 userId;
        address _tokenContract;
        address _creatorAccount;
    }
    Donate donate;

    //Buypowervote for eth
    function buypowervoteETH(
        uint256 value,
        uint256 voteId,
        uint256 userId
    )
        public
        payable
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        require(enableplatformfunctions == true);
        require(msg.value == value, "Value should be same");
        uint256 eventid = block.timestamp;
        (bool sent, ) = BuyETH.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit BuyPowerVoteETH(value, voteId, userId, eventid);
        return (value, voteId, userId, eventid);
    }

    //Buypowervote for ERC20
    function buypowervoteERC20(
        uint256 value,
        uint256 voteId,
        address _tokenContract,
        uint256 userId
    )
        external
        returns (
            uint256,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        require(enableplatformfunctions == true);
        uint256 eventid = block.timestamp;
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transferFrom(msg.sender, BuyETH, value);
        emit BuyPowerVoteERC20(value, voteId, _tokenContract, userId, eventid);
        return (value, voteId, _tokenContract, userId, eventid);
    }

    //DonateETH
    function donateETH(
        uint256 value,
        uint256 projectId,
        uint256 userId,
        address _creatorAccount
    )
        public
        payable
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint256
        )
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        require(enableplatformfunctions == true);
        require(msg.value == value, "Value should be same");
        uint256 eventid = block.timestamp;
        (bool sent, ) = Platform_donation.call{
            value: ((msg.value)*(4)/(100))}("");
        require(sent, "Failed to send Ether in platform donate wallet");
        (bool sentToCreator, ) = _creatorAccount.call{
            value: ((msg.value)*(96)/(100))
        }("");
        require(sentToCreator, "Failed to send Ether in creator account");
        emit DonateETH(value, projectId, userId, eventid, _creatorAccount);
        return (value, projectId, userId, _creatorAccount, eventid);
    }

    //Donate ERC20
    function donateERC20(
        uint256 value,
        uint256 projectId,
        uint256 userId,
        address _tokenContract,
        address _creatorAccount
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address,
            uint256
        )
    {
        require(enableplatformfunctions == true);
        donate = Donate(value,projectId,userId,_tokenContract,_creatorAccount);
        uint256 eventid = block.timestamp;
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(donate._tokenContract);
        uint256 platformAmount = (donate.value*(4)/(100));
        uint256 CreatorAmount = (donate.value*(96)/(100));
        tokenContract.transferFrom(msg.sender,Platform_donation,platformAmount);
        tokenContract.transferFrom(msg.sender,_creatorAccount,CreatorAmount);
        
        emit DonateERC20(
            donate.value,
             donate.projectId,
             donate.userId,
             donate._tokenContract,
             donate._creatorAccount,
            eventid
        );
        return (
            value,
            projectId,
            userId,
            _tokenContract,
            _creatorAccount,
            eventid
        );
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        whenNotPaused
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        whenNotPaused
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    function burn(uint256 amount)
        external
        virtual
        override
        onlyOwner
        whenNotPaused
        returns (bool)
    {
        _burn(_msgSender(), amount);
        return true;
    }

    function excludeFromDexFee(address account, bool feestate)
        external
        onlyOwner
        whenNotPaused
    {
        _isExcludedFromDexFee[account] = feestate;
    }

    function includeInDexFee(address account, bool feestate)
        external
        onlyOwner
        whenNotPaused
    {
        _isIncludedinFee[account] = feestate;
    }

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit TokenFromContractTransfered(_tokenContract, msg.sender, _amount);
    }

    function withdrawETHFromContract(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
        emit ETHFromContractTransferred(amount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _distributeFee() internal {
        // swap tokens in contract address to usdc
        IERC20 tokenContract = IERC20(usdccontractaddress);
        uint256 initialBalance = tokenContract.balanceOf(address(this));
        uint256 contractCreateBalance = balanceOf(address(this));
        uint256 totalSwapFee = gettotalSwapFee();
        bool feevalue = enableFee;
        enableFee = false;

        swapTokensForTokens(contractCreateBalance, address(this));

        uint256 ContractusdcBalance = tokenContract.balanceOf(address(this)) -
            initialBalance;

        // Send ETH to createProductions address
        if (createProductionsSwapEnabled)
            tokenContract.transfer(
                payable(createProductionsWallet),
                ContractusdcBalance *(createProductionsFee)/(totalSwapFee)
            );
        // Send ETH to cryptoToken address
        if (cryptoTokenSwapEnabled)
            tokenContract.transfer(
                payable(cryptoTokenWallet),
                ContractusdcBalance*(cryptoTokenFee)/(totalSwapFee)
            );
        // Send ETH to nft address
        if (nftSwapEnabled)
            tokenContract.transfer(
                payable(nftWallet),
                ContractusdcBalance*(nftFee)/(totalSwapFee)
            );
        // Send ETH to shortVideo address
        if (shortVideoSwapEnabled)
            tokenContract.transfer(
                payable(shortVideoWallet),
                ContractusdcBalance*(shortVideoFee)/(totalSwapFee)
            );
        //send ETH to musicwallet address
        if (musicSwapEnabled)
            tokenContract.transfer(
                payable(musicWallet),
                ContractusdcBalance*(musicFee)/(totalSwapFee)
            );

        //send ETH to events address
        if (eventsSwapEnabled)
            tokenContract.transfer(
                payable(eventsWallet),
                ContractusdcBalance*(eventsFee)/(totalSwapFee)
            );

        if (marketingSwapEnabled)
            tokenContract.transfer(
                payable(marketingWallet),
                ContractusdcBalance*(marketingFee)/(totalSwapFee)
            );

        if (staffWageSwapEnabled)
            tokenContract.transfer(
                payable(staffWageWallet),
                ContractusdcBalance*(staffFee)/(totalSwapFee)
            );

        enableFee = feevalue;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = balanceOf(from);
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (_isIncludedinFee[to]) {
            require(
                amount <= maxSellLimit,
                "ERC20: transfer amount exceeds sell limit"
            );
        }
        bool takeFee = false;
        if (_isIncludedinFee[from] || _isIncludedinFee[to]) {
            if (
                enableFee &&
                (!_isExcludedFromDexFee[from] && !_isExcludedFromDexFee[to])
            ) {
                takeFee = true;
                uint256 contractTokenBalance = balanceOf(address(this));

                if (
                    contractTokenBalance >= minimumTokensBeforeSwap &&
                    _isIncludedinFee[to]
                ) {
                    _distributeFee();
                }
            } else {
                takeFee = false;
            }
        }

        _tokenTransferTakeSwapFee(from, to, amount, takeFee);
    }

    function _tokenTransferTakeSwapFee(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal {
        address from = sender;
        address to = recipient;
        if (takeFee) {
            uint256 totalSwapFee = gettotalSwapFee();
            uint256 contractTokenBalance = balanceOf(address(this));
            balances[from] = balances[from]-(amount);
            uint256 tax = totalSwapFee *(amount)/(10000);
            balances[to] = balances[to]+(amount)-(tax);
            balances[address(this)] = contractTokenBalance + (tax);
            emit Transfer(sender, recipient, amount-(tax));
        } else {
            balances[from] = balances[from] - (amount);
            balances[to] = balances[to] + (amount);
            emit Transfer(sender, address(this), amount);
        }
    }

    function distributeFee() external onlyOwner {
        _distributeFee();
    }

    function transferETHToAddress(address payable recipient, uint256 amount)
        internal
    {
        recipient.transfer(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(
            amount < balanceOf(account),
            "ERC20: burn amount exceeds balance"
        );

        totalsupply = totalsupply - (amount);
        balances[account] = balances[account] - (amount);
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForTokens(uint256 tokenAmount, address account)
        internal
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = usdccontractaddress;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            account,
            block.timestamp
        );
    }

    function setCreateProductionsFeePercent(address addr, uint256 fee)
        external
        onlyOwner
    {
        createProductionsFee = fee;
        createProductionsWallet = addr;
        emit SetCreateProductionsFeePercent(createProductionsFee);
    }

    function setCryptoTokenFeePercent(address addr, uint256 fee)
        external
        onlyOwner
    {
        cryptoTokenFee = fee;
        cryptoTokenWallet = addr;
        emit SetCryptoTokenFeePercent(cryptoTokenFee);
    }

    function setNftFeePercent(address addr, uint256 fee) external onlyOwner {
        nftFee = fee;
        nftWallet = addr;
        emit SetNftFeePercent(nftFee);
    }

    function setShortVideoFeePercent(address addr, uint256 fee)
        external
        onlyOwner
    {
        shortVideoFee = fee;
        shortVideoWallet = addr;
        emit SetShortVideoFeePercent(shortVideoFee);
    }

    function setMusicFeePercent(address addr, uint256 fee) external onlyOwner {
        musicFee = fee;
        musicWallet = addr;
        emit SetMusicFeePercent(musicFee);
    }

    function setEventsFeePercent(address addr, uint256 fee) external onlyOwner {
        eventsFee = fee;
        eventsWallet = addr;
        emit SetEventsFeePercent(eventsFee);
    }

    function setMarketingFeePercent(address addr, uint256 fee)
        external
        onlyOwner
    {
        marketingFee = fee;
        marketingWallet = addr;
        emit SetMarketingFeePercent(fee);
    }

    function setStaffFeePercent(address addr, uint256 fee) external onlyOwner {
        staffFee = fee;
        staffWageWallet = addr;
        emit SetStaffFeePercent(fee);
    }

    function setCreateProductionsSwapEnabled(bool enable) external onlyOwner {
        createProductionsSwapEnabled = enable;
        emit SetCreateProductionsSwapEnabled(createProductionsSwapEnabled);
    }

    function setCryptoTokenSwapEnabled(bool enable) external onlyOwner {
        cryptoTokenSwapEnabled = enable;
        emit SetCryptoTokenSwapEnabled(cryptoTokenSwapEnabled);
    }

    function setNftSwapEnabled(bool enable) external onlyOwner {
        nftSwapEnabled = enable;
        emit SetNftSwapEnabled(nftSwapEnabled);
    }

    function setShortVideoSwapEnabled(bool enable) external onlyOwner {
        shortVideoSwapEnabled = enable;
        emit SetShortVideoSwapEnabled(shortVideoSwapEnabled);
    }

    function setMusicSwapEnabled(bool enable) external onlyOwner {
        musicSwapEnabled = enable;
        emit SetMusicSwapEnabled(musicSwapEnabled);
    }

    function setEventsSwapEnabled(bool enable) external onlyOwner {
        eventsSwapEnabled = enable;
        emit SetEventsSwapEnabled(eventsSwapEnabled);
    }

    function setMarketingSwapEnabled(bool enable) external onlyOwner {
        marketingSwapEnabled = enable;
        emit SetMarketingSwapEnabled(enable);
    }

    function setStaffSwapEnabled(bool enable) external onlyOwner {
        staffWageSwapEnabled = enable;
        emit SetStaffSwapEnabled(enable);
    }

    function setMaximumSellLimitUniswap(uint256 sellLimit) external onlyOwner {
        maxSellLimit = sellLimit;
        emit SetMaximumSellLimitUniswap(maxSellLimit);
    }

    function setMinimumTokensBeforeSwap(uint256 swapLimit) external onlyOwner {
        minimumTokensBeforeSwap = swapLimit;
        emit SetMinimumTokensBeforeSwap(minimumTokensBeforeSwap);
    }

    function setEnableFee(bool enableTax) external onlyOwner {
        enableFee = enableTax;
        emit FeeEnabled(enableTax);
    }
}