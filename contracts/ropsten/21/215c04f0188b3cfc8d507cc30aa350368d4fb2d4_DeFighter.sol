/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBEP20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, TOKEN the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
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
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract DeFighter is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _bots;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    string private _name = "DeFighter";
    string private _symbol = unicode"$DFC";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 250000000 * 1e9;

    IPancakeRouter02 public pancakeRouter;
    address public immutable uniSwapPair;

    address payable private rewardsWallet;
    address payable private donationWallet;
    address payable private marketingWallet;
    address payable private developmentWallet;

    uint256 _rewardsTax;
    uint256 public _rewardsTaxForBuying = 20; // 2%
    uint256 public _rewardsTaxForSelling = 20;

    uint256 _donationTax;
    uint256 public _donationTaxForBuying = 20;
    uint256 public _donationTaxForSelling = 20;

    uint256 _marketingTax;
    uint256 public _marketingTaxForBuying = 20;
    uint256 public _marketingTaxForSelling = 20;

    uint256 _developmentTax;
    uint256 public _developmentTaxForBuying = 20;
    uint256 public _developmentTaxForSelling = 20;

    bool public swapAndLiquifyEnabled = false;
    bool inSwapAndLiquify = false;

    uint256 public maxTxAmount = 200000 * 10**9; // 0.08% of total suppy
    uint256 public minTokenNumberToSell = 20000 * 10**9; // 0.008% of total supply
    uint256 public maxHoldingAmount = 200000 * 10**9; // 0.08% of total supply by default
    uint256 public sellCoolDownTriggeredAt = block.timestamp;
    uint256 public sellCoolDownDuration = 1 seconds;
    uint256 public buyCoolDownTriggeredAt = block.timestamp;
    uint256 public buyCoolDownDuration = 45 seconds;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address payable _rewardsWallet,
        address payable _donationWallet,
        address payable _marketingWallet,
        address payable _developmentWallet
    ) {
        _tOwned[owner()] = _tTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Create a pancake pair for this new token
        uniSwapPair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        rewardsWallet = _rewardsWallet;
        donationWallet = _donationWallet;
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_rewardsWallet] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        // exlude from max wallet
        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[_rewardsWallet] = true;
        _isExcludedFromMaxWallet[_donationWallet] = true;
        _isExcludedFromMaxWallet[_marketingWallet] = true;
        _isExcludedFromMaxWallet[_developmentWallet] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //to receive BNB
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BUT: transfer amount exceeds allowance"
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
                "BUT: decreased allowance below zero"
            )
        );
        return true;
    }

    // getter functions

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isBot(address account) public view returns (bool) {
        return _bots[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setBot(address account) public onlyOwner {
        _bots[account] = true;
    }

    function setBots(address[] memory bots) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            _bots[bots[i]] = true;
        }
    }

    function delBot(address account) public onlyOwner {
        _bots[account] = false;
    }

    function delBots(address[] memory bots) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            _bots[bots[i]] = false;
        }
    }

    function excludeFromTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setAmountLimits(uint256 _maxTxAmount, uint256 _maxHoldAmount)
        public
        onlyOwner
    {
        maxTxAmount = _maxTxAmount;
        maxHoldingAmount = _maxHoldAmount;
    }

    function setAllBuyTaxes(
        uint256 _bRewardsTax,
        uint256 _bDonationTax,
        uint256 _bMarketingTax,
        uint256 _bDevelopmentTax
    ) external onlyOwner {
        _rewardsTaxForBuying = _bRewardsTax;
        _donationTaxForBuying = _bDonationTax;
        _marketingTaxForBuying = _bMarketingTax;
        _developmentTaxForBuying = _bDevelopmentTax;
    }

    function setSllSellTaxes(
        uint256 _sRewardsTax,
        uint256 _sDonationTax,
        uint256 _sMarketingTax,
        uint256 _sDevelopmentTax
    ) external onlyOwner {
        _rewardsTaxForSelling = _sRewardsTax;
        _donationTaxForSelling = _sDonationTax;
        _marketingTaxForSelling = _sMarketingTax;
        _developmentTaxForSelling = _sDevelopmentTax;
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool _state)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = _state;
    }

    function setExcludeFromMaxWallet(address _address, bool _state)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[_address] = _state;
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setNewTaxWallets(
        address payable _rewardsWallet,
        address payable _donationWallet,
        address payable _marketingWallet,
        address payable _developmentWallet
    ) external onlyOwner {
        rewardsWallet = _rewardsWallet;
        donationWallet = _donationWallet;
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;
    }

    function setRewardsWallet(address payable _rewardsWallet)
        external
        onlyOwner
    {
        rewardsWallet = _rewardsWallet;
    }

    function setDonationWallet(address payable _donationWallet)
        external
        onlyOwner
    {
        donationWallet = _donationWallet;
    }

    function setMarketingWallet(address payable _marketingWallet)
        external
        onlyOwner
    {
        marketingWallet = _marketingWallet;
    }

    function setDevelopmentWallet(address payable _developmentWallet)
        external
        onlyOwner
    {
        developmentWallet = _developmentWallet;
    }

    function enableCoolDown() external onlyOwner {
        buyCoolDownDuration = 45 seconds;
    }

    function diableCoolDown() external onlyOwner {
        buyCoolDownDuration = 0 seconds;
    }

    function removeMaxTxLimit() external onlyOwner {
        maxTxAmount = _tTotal;
    }

    function setMaxTxLimit(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function setPancakeRouter(IPancakeRouter02 _pancakeRouter)
        external
        onlyOwner
    {
        pancakeRouter = _pancakeRouter;
    }

    // internal functions for contract

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount
            .mul(
                _rewardsTax.add(_donationTax).add(_marketingTax).add(
                    _developmentTax
                )
            )
            .div(1e3);
        return percentage;
    }

    function _takeAllFee(uint256 tAmount) internal {
        uint256 tFee = tAmount
            .mul(
                _rewardsTax.add(_donationTax).add(_marketingTax).add(
                    _developmentTax
                )
            )
            .div(1e3);

        _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
        emit Transfer(_msgSender(), address(this), tFee);
    }

    function removeAllFee() private {
        _rewardsTax = 0;
        _donationTax = 0;
        _marketingTax = 0;
        _developmentTax = 0;
    }

    function takeBuyFee() private {
        _rewardsTax = _rewardsTaxForBuying;
        _donationTax = _donationTaxForBuying;
        _marketingTax = _marketingTaxForBuying;
        _developmentTax = _developmentTaxForBuying;
    }

    function takeSellFee() private {
        _rewardsTax = _rewardsTaxForSelling;
        _donationTax = _donationTaxForSelling;
        _marketingTax = _marketingTaxForSelling;
        _developmentTax = _developmentTaxForSelling;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "TOKEN: approve from the zero address");
        require(spender != address(0), "TOKEN: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "TOKEN: transfer from the zero address");
        require(to != address(0), "TOKEN: transfer to the zero address");
        require(amount > 0, "TOKEN: Transfer amount must be greater than zero");
        require(!_bots[from] && !_bots[to] && !_bots[msg.sender]);

        if (
            !_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to] // by default false
        ) {
            require(amount <= maxTxAmount, "TOKEN: Amount exceed max limit");

            if (to != uniSwapPair && !_isExcludedFromMaxWallet[to]) {
                require(
                    balanceOf(to).add(amount) <= maxHoldingAmount,
                    "TOKEN: max holding limit exceeds"
                );
            }

            if (from == uniSwapPair) {
                require(
                    buyCoolDownTriggeredAt.add(buyCoolDownDuration) <
                        block.timestamp,
                    "TOKEN: wait for buying cool down"
                );
                buyCoolDownTriggeredAt = block.timestamp;
            }

            if (to == uniSwapPair) {
                require(
                    sellCoolDownTriggeredAt.add(sellCoolDownDuration) <
                        block.timestamp,
                    "TOKEN: wait for selling cool down"
                );
                sellCoolDownTriggeredAt = block.timestamp;
            }
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    // take fee if takefee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        else if (sender == uniSwapPair) takeBuyFee();
        else takeSellFee();

        uint256 tTransferAmount = amount.sub(totalFeePerTx(amount));
        _tOwned[sender] = _tOwned[sender].sub(amount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _takeAllFee(amount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function manualSwap() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        _approve(address(this), address(pancakeRouter), contractTokenBalance);
        swapTokensForBNB(contractTokenBalance);
    }

    function manualSend() external onlyOwner {
        uint256 deltaBalance = getContractBalance();
        uint256 totalPercent = _rewardsTax
            .add(_donationTax)
            .add(_marketingTax)
            .add(_developmentTax);

        uint256 rewardPercent = _rewardsTax.mul(1e4).div(totalPercent);
        uint256 donationPercent = _donationTax.mul(1e4).div(totalPercent);
        uint256 marketingPercent = _marketingTax.mul(1e4).div(totalPercent);
        uint256 developmentPercent = _developmentTax.mul(1e4).div(totalPercent);

        totalPercent = rewardPercent
            .add(donationPercent)
            .add(marketingPercent)
            .add(developmentPercent);

        rewardsWallet.transfer(
            deltaBalance.mul(rewardPercent).div(totalPercent)
        );
        donationWallet.transfer(
            deltaBalance.mul(donationPercent).div(totalPercent)
        );
        marketingWallet.transfer(
            deltaBalance.mul(marketingPercent).div(totalPercent)
        );
        developmentWallet.transfer(
            deltaBalance.mul(developmentPercent).div(totalPercent)
        );
    }

    function swapAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != uniSwapPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(uniSwapPair))
        ) {
            // split the contract balance into 4 pieces

            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(
                address(this),
                address(pancakeRouter),
                contractTokenBalance
            );

            takeSellFee();
            uint256 totalPercent = _rewardsTax
                .add(_donationTax)
                .add(_marketingTax)
                .add(_developmentTax);

            uint256 rewardPercent = _rewardsTax.mul(1e4).div(totalPercent);
            uint256 donationPercent = _donationTax.mul(1e4).div(totalPercent);
            uint256 marketingPercent = _marketingTax.mul(1e4).div(totalPercent);
            uint256 developmentPercent = _developmentTax.mul(1e4).div(
                totalPercent
            );

            swapTokensForBNB(contractTokenBalance);

            uint256 deltaBalance = getContractBalance();

            totalPercent = rewardPercent
                .add(donationPercent)
                .add(marketingPercent)
                .add(developmentPercent);

            // tax transfers
            rewardsWallet.transfer(
                deltaBalance.mul(rewardPercent).div(totalPercent)
            );
            donationWallet.transfer(
                deltaBalance.mul(donationPercent).div(totalPercent)
            );
            marketingWallet.transfer(
                deltaBalance.mul(marketingPercent).div(totalPercent)
            );
            developmentWallet.transfer(
                deltaBalance.mul(developmentPercent).div(totalPercent)
            );
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) internal lockTheSwap {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
}