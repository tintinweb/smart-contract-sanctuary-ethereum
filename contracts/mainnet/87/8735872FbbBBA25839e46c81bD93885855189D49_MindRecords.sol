/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC721 {
    function depositReward() external payable;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }

    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _name;
    string private _symbol;

    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 __totalSupply
    ){
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _totalSupply = __totalSupply;

    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
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
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        _basicTransfer(sender, recipient, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address uniswapV2Pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address uniswapV2Pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract MindRecords is ERC20, Ownable {
    using Address for address payable;
    using SafeERC20 for IERC20;
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    

    bool private _liquidityLock = false;
    bool public providingLiquidity = false;
    bool public tradingActive = false;

    uint256 public tokenLiquidityThreshold;

    uint256 public tradeStartBlock;


    bool private autoHandleFee = true;

    address public mindRecordsFundAddress;
    address public nftRewardContract;
    bool public isNftRewardEnabled;
    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;

    struct Fees {
        uint256 mindRecordFund;
        uint256 nftReward;
    }

    Fees public buyFees = Fees(3, 1);
    Fees public sellFees = Fees(3, 1);

    uint256 private totalBuyFeeAmount = 0;
    uint256 private totalSellFeeAmount = 0;

    mapping(address => bool) public exemptFee;



    constructor(address router_, address _feeAddress) 
        ERC20("Mind Records","MIND",9,50000000 * 10**9)
    {
        _owner = msg.sender;
        mindRecordsFundAddress = _feeAddress;
        nftRewardContract = _feeAddress;

        IRouter _router = IRouter(router_);
        // Create a pancake uniswapV2Pair for this new token
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
    
        uniswapV2Router = _router;
        uniswapV2Pair = _pair;

        tokenLiquidityThreshold =  (totalSupply() / 1000) * 2; // .2% liq threshold

        _beforeTokenTransfer(address(0), msg.sender, totalSupply());

        // _totalSupply += _totalSupply;
        _balances[msg.sender] += totalSupply();

        exemptFee[msg.sender] = true;
        exemptFee[address(this)] = true;
        exemptFee[mindRecordsFundAddress] = true;
        exemptFee[deadWallet] = true;

        emit Transfer(address(0), msg.sender, totalSupply());
        
    }

   modifier lockLiquidity() {
        if (!_liquidityLock) {
            _liquidityLock = true;
            _;
            _liquidityLock = false;
        }
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
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
        public
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingActive, "Trading is not enabled");
        }

        uint256 feeRatio;
        uint256 feeAmount;
        uint256 buyOrSell;

        //set fee amount to zero if fees in contract are handled or exempted
        if (
            _liquidityLock ||
            exemptFee[sender] ||
            exemptFee[recipient] ||
            (sender != uniswapV2Pair && recipient != uniswapV2Pair)
        )
            feeAmount = 0;

            //calculate fees
        else if (recipient == uniswapV2Pair) {
            feeRatio = sellFees.nftReward + sellFees.mindRecordFund ;
            buyOrSell = 1;
        } else  {
            feeRatio = buyFees.nftReward + buyFees.mindRecordFund ;
            buyOrSell = 0;
        } 
        feeAmount = (amount * feeRatio) / 100;

        if (buyOrSell == 0) {
            totalBuyFeeAmount += feeAmount;
        } else if (buyOrSell == 1) {
            totalSellFeeAmount += feeAmount;
        }

        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (feeAmount > 0) {
            _transfer(sender, address(this), feeAmount);
        }

        if (
            providingLiquidity &&
            sender != uniswapV2Pair &&
            feeAmount > 0 &&
            autoHandleFee &&
            balanceOf(address(this)) >= tokenLiquidityThreshold
        ) {
            swapBack(totalBuyFeeAmount);
        }

        //rest to recipient
        super._transfer(sender, recipient, amount - feeAmount);
    }

    function swapBack(uint256 _totalBuyFeeAmount) private lockLiquidity {
        uint256 contractBalance = balanceOf(address(this));
        totalBuyFeeAmount = _totalBuyFeeAmount;
        totalSellFeeAmount = contractBalance - totalBuyFeeAmount;

        if (contractBalance > 0) {
            swapTokensForETH(contractBalance);
        }

        uint256 finalBalance = address(this).balance;


        uint256 sellFeeMindRecordFundEth;
        uint256 buyFeeMindRecordFundEth;

        uint256 sellFeeNftReward;
        uint256 buyFeeNftReward;

        if( totalSellFees() > 0){
            uint256 totalSellFeeEth = (finalBalance * totalSellFeeAmount) / contractBalance;
            sellFeeMindRecordFundEth = (totalSellFeeEth * sellFees.mindRecordFund) / totalSellFees();
            sellFeeNftReward = (totalSellFeeEth * sellFees.nftReward) / totalSellFees();
        }

        if(totalBuyFees() > 0){
        uint256 totalBuyFeeEth = (finalBalance * totalBuyFeeAmount) / contractBalance;

            buyFeeMindRecordFundEth = (totalBuyFeeEth * buyFees.mindRecordFund) / totalBuyFees();
            buyFeeNftReward = (totalBuyFeeEth * buyFees.nftReward) / totalBuyFees();
        }

        if (sellFeeMindRecordFundEth + buyFeeMindRecordFundEth > 0) {
            payable(mindRecordsFundAddress).sendValue(sellFeeMindRecordFundEth + buyFeeMindRecordFundEth);
        }

        if (sellFeeNftReward + buyFeeNftReward > 0) {
            if(isNftRewardEnabled){
          IERC721(nftRewardContract).depositReward{value:sellFeeNftReward + buyFeeNftReward}();
            }else{
            payable(nftRewardContract).sendValue(sellFeeNftReward + buyFeeNftReward);

            }

        }
        
        totalBuyFeeAmount = 0;
        totalSellFeeAmount = 0;
    }

    function handleFee(uint256 _totalBuyFeeAmount) external onlyOwner {
        swapBack(_totalBuyFeeAmount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pancake uniswapV2Pair path of token -> weth

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }


    function updateLiquidityProvide(bool flag) external onlyOwner {
        require(
            providingLiquidity != flag,
            "You must provide a different status other than the current value in order to update it"
        );
        //update liquidity providing state
        providingLiquidity = flag;
    }

    function updateLiquidityThreshold(uint256 new_amount) external onlyOwner {
        //update the treshhold
        require(
            tokenLiquidityThreshold != new_amount * 10**decimals(),
            "You must provide a different amount other than the current value in order to update it"
        );
        tokenLiquidityThreshold = new_amount * 10**decimals();
    }

    function updateBuyFees(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        buyFees = Fees(_marketing, _liquidity);
        require(
           (_marketing + _liquidity) <= 30,
            "Must keep fees at 30% or less"
        );
    }

    function updateSellFees(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        sellFees = Fees(_marketing, _liquidity);
        require(
           (_marketing + _liquidity) <= 30,
            "Must keep fees at 30% or less"
        );
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
        providingLiquidity = true;
        tradeStartBlock = block.number;
    }

    function getStuckEth(uint256 amount, address receiveAddress)
        external
        onlyOwner
    {
        payable(receiveAddress).transfer(amount);
    }

    function getStuckToken(
        IERC20 _token,
        address receiveAddress,
        uint256 amount
    ) external onlyOwner {
        _token.safeTransfer(receiveAddress, amount);
    }

    function updateExemptFee(address _address, bool flag) external onlyOwner {
        require(
            exemptFee[_address] != flag,
            "You must provide a different exempt address or status other than the current value in order to update it"
        );
        exemptFee[_address] = flag;
    }

    function bulkExemptFee(address[] memory accounts, bool flag)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = flag;
        }
    }

    function handleFeeStatus(bool _flag) external onlyOwner {
        autoHandleFee = _flag;
    }

    function setRouter(address newRouter)
        external
        onlyOwner
        returns (address _pair)
    {
        require(newRouter != address(0), "newRouter address cannot be 0");
        require(
            uniswapV2Router != IRouter(newRouter),
            "You must provide a different uniswapV2Router other than the current uniswapV2Router address in order to update it"
        );
        IRouter _router = IRouter(newRouter);

        _pair = IFactory(_router.factory()).getPair(
            address(this),
            _router.WETH()
        );
        if (_pair == address(0)) {
            // uniswapV2Pair doesn't exist
            _pair = IFactory(_router.factory()).createPair(
                address(this),
                _router.WETH()
            );
        }

        // Set the uniswapV2Pair of the contract variables
        uniswapV2Pair = _pair;
        // Set the uniswapV2Router of the contract variables
        uniswapV2Router = _router;
    }

    function updateMindRecordFundWallet(address newWallet) external onlyOwner {
        require(
            mindRecordsFundAddress != newWallet,
            "You must provide a different address other than the current value in order to update it"
        );
        mindRecordsFundAddress = newWallet;
    }

    function setNftAddress(address _address, bool _flag) external onlyOwner {
        nftRewardContract = _address;
        isNftRewardEnabled = _flag;
    }
    
    function totalBuyFees() internal view returns(uint256) {
        return buyFees.nftReward + buyFees.mindRecordFund;
    }

    function totalSellFees() internal view returns(uint256) {
        return sellFees.nftReward + sellFees.mindRecordFund;
    }
    // fallbacks
    receive() external payable {}

}