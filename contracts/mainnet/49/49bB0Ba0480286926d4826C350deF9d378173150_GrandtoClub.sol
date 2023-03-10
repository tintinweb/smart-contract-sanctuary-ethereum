//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./IERC20.sol";
import "./blacklist.sol";
import "./safeMath.sol";
import "./ownable.sol";
import "./address.sol";
import "./liquifier.sol";
import "./IERC20Metadata.sol";

abstract contract Tokenomics {
    using SafeMath for uint256;

    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
 
    address public developerFEEAddress =
        0xb280eB22334f4c3b0cC2fE6C5665FE11B15AE5e3;

    uint256 public _devFee = 0; // 0%
    uint256 public _liqFee = 50; // 5%

    string internal constant NAME = "GrandtoClub";
    string internal constant SYMBOL = "GTC";

    uint16 internal constant FEES_DIVISOR = 10**3;
    uint8 internal constant DECIMALS = 18;
    uint256 internal constant ZEROES = 10**DECIMALS;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 100000000 * ZEROES; // 10 MM

    uint256 public MXTX = 1500000;
    uint256 public maxTransactionAmount = MXTX * ZEROES; // 1.50% of the total supply //1500000

    uint256 public MXWL = 1500000;

    uint256 public maxWalletBalance = MXWL * ZEROES; // 1.50% of the total supply //1500000

    uint256 public numberOfTokensToSwapToLiquidity =
        TOTAL_SUPPLY / 10000; // 0.1% of the total supply //10k in contract before liq

    // --------------------- Fees Settings ------------------- //

    enum FeeType {
        Liquidity,
        ExternalToETH
    }
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(
        FeeType name,
        uint256 value,
        address recipient
    ) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }

    function _addFees() private {

        _addFee(FeeType.Liquidity, _liqFee, address(this)); //2%
        _addFee(FeeType.ExternalToETH, _devFee, developerFEEAddress); //2%
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    function _getFee(uint256 index)
        internal
        view
        returns (
            FeeType,
            uint256,
            address,
            uint256
        )
    {
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    // function getCollectedFeeTotal(uint256 index) external view returns (uint256){
    function getCollectedFeeTotal(uint256 index)
        internal
        view
        returns (uint256)
    {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}

abstract contract Base is
    IERC20,
    IERC20Metadata,
    Ownable,
    Tokenomics,
    Blacklist
{
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromFee;

    constructor() {
        _balances[owner()] = TOTAL_SUPPLY;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[developerFEEAddress] = true;
        _isExcludedFromFee[uniswapV2Router] = true;
        _isExcludedFromFee[address(this)] = true;

        _addToWhitelistedSenders(owner());
        _addToWhitelistedSenders(developerFEEAddress);
        _addToWhitelistedSenders(address(this));
        _addToWhitelistedSenders(uniswapV2Router);

        _addToWhitelistedRecipients(owner());
        _addToWhitelistedRecipients(developerFEEAddress);
        _addToWhitelistedRecipients(address(this));
        _addToWhitelistedRecipients(uniswapV2Router);

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }
    
    function changeMaxTxAmount(uint256 newAmount) public onlyOwner {
        MXTX = newAmount;
    }
       function changeMaxWalletAMount(uint256 newAmount) public onlyOwner {
        MXWL = newAmount;
    }

      function changeDevFeeAddress(address _newDevFeeAddress) public onlyOwner {
        developerFEEAddress = _newDevFeeAddress;
    }

    function changeDevFee(uint256 _newDevFee) public onlyOwner {
        uint256 _sumOfFees = _liqFee + _newDevFee;
        require(_sumOfFees <= 50, "Total fees cannot be more than 5%");
        _devFee = _newDevFee;
    }

    function changeLiqFee(uint256 _newLiqFee) public onlyOwner {
        uint256 _sumOfFees = _devFee + _newLiqFee;
        require(_sumOfFees <= 50, "Total fees cannot be more than 5%");
        _liqFee = _newLiqFee;
    }

    function blackListWallets(address _wallet, bool _status) public onlyOwner {
        antiBot._blacklistedUsers[_wallet] = _status; // true or false
    }

    // BLACKLIST ARRAY OF ADDRESSES EG: ["0X000...","0X000","0X000"],true
    function blackListWalletsBulk(address[] memory _wallets, bool _status)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            antiBot._blacklistedUsers[_wallets[i]] = _status;
        }
    }

    function removeBlackListWallet(address _wallet) public onlyOwner {
        antiBot._blacklistedUsers[_wallet] = false;
    }

    function removeBlackListWalletBulk(address[] memory _wallets)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            antiBot._blacklistedUsers[_wallets[i]] = false;
        }
    }

    /** Functions required by IERC20Metadata **/
    function name() external pure override returns (string memory) {
        return NAME;
    }

    function symbol() external pure override returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    /** Functions required by IERC20 **/
    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function setExcludedFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "BaseRfiToken: approve from the zero address"
        );
        require(
            spender != address(0),
            "BaseRfiToken: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    address[] private whitelistedSenders;
    address[] private whitelistedRecipients;

    function _isUnlimitedSender(address account) public view returns (bool) {
        // check if the provided address is in the whitelisted senders array or is the owner
        for (uint256 i = 0; i < whitelistedSenders.length; i++) {
            if (account == whitelistedSenders[i] || account == owner()) {
                return true;
            }
        }
        return false;
    }

    function _isUnlimitedRecipient(address account) public view returns (bool) {
        // check if the provided address is in the whitelisted recipients array or is the owner
        for (uint256 i = 0; i < whitelistedRecipients.length; i++) {
            if (account == whitelistedRecipients[i] || account == owner()) {
                return true;
            }
        }
        return false;
    }

    function _addToWhitelistedSenders(address account) internal {
        whitelistedSenders.push(account);
    }

    function addToWhitelistedSenders(address account) external onlyOwner {
        whitelistedSenders.push(account);
    }

    function removeFromWhitelistedSenders(address account) external onlyOwner {
        for (uint256 i = 0; i < whitelistedSenders.length; i++) {
            if (whitelistedSenders[i] == account) {
                whitelistedSenders[i] = whitelistedSenders[
                    whitelistedSenders.length - 1
                ];
                whitelistedSenders.pop();
                break;
            }
        }
    }

    function _addToWhitelistedRecipients(address account) internal {
        whitelistedRecipients.push(account);
    }

    function addToWhitelistedRecipients(address account) external onlyOwner {
        whitelistedRecipients.push(account);
    }

    function removeFromWhitelistedRecipients(address account)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < whitelistedRecipients.length; i++) {
            if (whitelistedRecipients[i] == account) {
                whitelistedRecipients[i] = whitelistedRecipients[
                    whitelistedRecipients.length - 1
                ];
                whitelistedRecipients.pop();
                break;
            }
        }
    }

    bool public tradeStarted = false;

    // once enabled, can never be turned off
    function EnableTrading() external onlyOwner {
        tradeStarted = true;
    }

    modifier isTradeStarted(address from, address to) {
        if (!tradeStarted) {
            require(
                _isUnlimitedSender(from) || _isUnlimitedRecipient(to),
                "trade not started"
            );
        }

        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private isTradeStarted(sender, recipient) {
        require(
            sender != address(0),
            "BaseRfiToken: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "BaseRfiToken: transfer to the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !antiBot._blacklistedUsers[recipient] &&
                !antiBot._blacklistedUsers[sender],
            "You are not allowed"
        );

        // indicates whether or not feee should be deducted from the transfer
        bool takeFee = true;

        if (
            amount > maxTransactionAmount &&
            !_isUnlimitedSender(sender) &&
            !_isUnlimitedRecipient(recipient)
        ) {
            revert("Transfer amount exceeds the maxTxAmount.");
        }

        if (
            maxWalletBalance > 0 &&
            !_isUnlimitedSender(sender) &&
            !_isUnlimitedRecipient(recipient) &&
            !_isV2Pair(recipient)
        ) {
            uint256 recipientBalance = balanceOf(recipient);
            require(
                recipientBalance + amount <= maxWalletBalance,
                "New balance would exceed the maxWalletBalance"
            );
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _beforeTokenTransfer(sender, recipient, amount, takeFee);
        _transferTokens(sender, recipient, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 sumOfFees = _getSumOfFees(sender, amount);
        if (!takeFee) {
            sumOfFees = 0;
        }

        (uint256 tAmount, uint256 tTransferAmount) = _getValues(
            amount,
            sumOfFees
        );

        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        _takeFees(amount, sumOfFees);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(uint256 amount, uint256 sumOfFees) private {
        if (sumOfFees > 0) {
            _takeTransactionFees(amount);
        }
    }

    function _getValues(uint256 tAmount, uint256 feesSum)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);

        return (tAmount, tTransferAmount);
    }

    function _getCurrentSupply() internal pure returns (uint256) {
        uint256 tSupply = TOTAL_SUPPLY;
        return (tSupply);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal virtual;

    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev A delegate which should return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns (bool);

    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(uint256 amount) internal virtual;
}

abstract contract Grandto is Base, Liquifier {
    using SafeMath for uint256;

    // constructor(string memory _name, string memory _symbol, uint8 _decimals){
    constructor(Env _env) {
        initializeLiquiditySwapper(
            _env,
            maxTransactionAmount,
            numberOfTokensToSwapToLiquidity
        );
    }

    function _isV2Pair(address account) internal view override returns (bool) {
        return (account == _pair);
    }

    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        return _getAntiwhaleFees(balanceOf(sender), amount);
    }

    function _getAntiwhaleFees(uint256, uint256)
        internal
        view
        returns (uint256)
    {
        return sumOfFees;
    }

    // function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal override {
    function _beforeTokenTransfer(
        address sender,
        address,
        uint256,
        bool
    ) internal override {
        uint256 contractTokenBalance = balanceOf(address(this));
        liquify(contractTokenBalance, sender);
    }

    function _takeTransactionFees(uint256 amount) internal override {
        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++) {
            (FeeType name, uint256 value, address recipient, ) = _getFee(index);
            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if (value == 0) continue;
            else if (name == FeeType.ExternalToETH) {
                _takeFee(amount, value, recipient, index);
            } else {
                _takeFee(amount, value, recipient, index);
            }
        }
    }

    function _takeFee(
        uint256 amount,
        uint256 fee,
        address recipient,
        uint256 index
    ) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);

        _balances[recipient] = _balances[recipient].add(tAmount);
        _addFeeCollectedAmount(index, tAmount);
    }

    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        _approve(owner, spender, amount);
    }
}

contract GrandtoClub is Grandto {
    constructor() Grandto(Env.MainnetV2) {
        // pre-approve the initial liquidity supply (to safe a bit of time)
        _approve(owner(), address(_router), ~uint256(0));
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IERC20.sol";
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ownable.sol";
import "./safeMath.sol";
import "./uniswap.sol";

abstract contract Liquifier is Ownable {
    using SafeMath for uint256;

    uint256 private withdrawableBalance;

    enum Env {
        MainnetV2
    }
    Env private _env;

    address public _mainnetRouterV2Address =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IPancakeV2Router internal _router;
    address internal _pair;

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToLiquidity;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(
        uint256 tokenAmountSent,
        uint256 ethAmountSent,
        uint256 liquidity
    );

    receive() external payable {}

    function initializeLiquiditySwapper(
        Env env,
        uint256 maxTx,
        uint256 liquifyAmount
    ) internal {
        _env = env;
        if (_env == Env.MainnetV2) {
            _setRouterAddress(_mainnetRouterV2Address);
        }

        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToLiquidity = liquifyAmount;
    }

    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function liquify(uint256 contractTokenBalance, address sender) internal {
        if (contractTokenBalance >= maxTransactionAmount)
            contractTokenBalance = maxTransactionAmount;

        bool isOverRequiredTokenBalance = (contractTokenBalance >=
            numberOfTokensToSwapToLiquidity);

        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the uniswap pair
         */
        if (
            isOverRequiredTokenBalance &&
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            (sender != _pair)
        ) {
            // TODO check if the `(sender != _pair)` is necessary because that basically
            // stops swap and liquify for all "buy" transactions
            _swapAndLiquify(contractTokenBalance);
        }
    }

    /**
     * @dev sets the router address and created the router, factory pair to enable
     * swapping and liquifying (contract) tokens
     */
    function _setRouterAddress(address router) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(
            address(this),
            _newPancakeRouter.WETH()
        );
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approveDelegate(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

 function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approveDelegate(address(this), address(_router), tokenAmount);

        // add tahe liquidity
        (
            uint256 tokenAmountSent,
            uint256 ethAmountSent,
            uint256 liquidity
        ) = _router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );

        // fix the forever locked BNBs/ETH as per the certik's audit
        /**
         * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB.
         * For every swapAndLiquify function call, a small amount of BNB remains in the contract.
         * This amount grows over time with the swapAndLiquify function being called throughout the life
         * of the contract. EG: The Safemoon contract does not contain a method to withdraw these funds,
         * and the ETH/BNB will be locked in the Safemoon v1 contract forever.
         */
        withdrawableBalance = address(this).balance;
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }
    
     /**
     * @dev The owner can withdraw ETH(BNB) collected in the contract from `swapAndLiquify`
     * or if someone (accidentally) sends ETH/BNB directly to the contract.
     *
     * Note: This addresses the contract flaw pointed out in the Certik Audit of Safemoon (SSL-03):
     *
     * The swapAndLiquify function converts half of the contractTokenBalance SafeMoon tokens to BNB.
     * For every swapAndLiquify function call, a small amount of BNB remains in the contract.
     * This amount grows over time with the swapAndLiquify function being called
     * throughout the life of the contract. The Safemoon contract does not contain a method
     * to withdraw these funds, and the BNB will be locked in the Safemoon contract forever.
     * https://www.certik.org/projects/safemoon
     */
    function withdrawLockedEth(address payable recipient) external onlyOwner {
        require(
            recipient != address(0),
            "Cannot withdraw the ETH balance to the zero address"
        );
        require(
            withdrawableBalance > 0,
            "The ETH balance must be greater than 0"
        );

        // prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }

    /**
     * @dev Sends the swap and liquify flag to the provided value. If set to `false` tokens collected in the contract will
     * NOT be converted into liquidity.
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `BaseRfiToken` to gained access
     * to the `_approve` function.
     */
    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./context.sol";

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Blacklist {
    struct AntiBot {
        mapping(address => bool) _blacklistedUsers;
    }
    AntiBot antiBot;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
interface IPancakeV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakeV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}