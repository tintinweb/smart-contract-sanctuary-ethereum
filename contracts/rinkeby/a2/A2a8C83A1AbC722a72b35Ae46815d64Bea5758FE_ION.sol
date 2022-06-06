// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

//TODO CHANGE ONE YEAR TIME AND BUT TAX TIME (RECHARGE PERIOD)
//TODO CHANGE TWENTYFOURHOURS TIME
//TODO We have to change PCT_BASE to 10000
//TODO Uncomment the distribution code
//TODO Put zero check for rewards before transferring
//TODO Adjust price decimals as per USDC (10**6)
//TODO Confirm the value of epochEndAmount to be set in constructor
//TODO check the initial cool down period before the start of first epoch
//TODO list of all the %s to be set at deployment
//TODO check if need transfer pause functioanlity

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./mock_router/interfaces/IUniswapV2Factory.sol";
import "./mock_router/interfaces/IUniswapV2Router02.sol";
import "./mock_router/interfaces/IUniswapV2Pair.sol";

import "./interfaces/ISuperCharge.sol";
import "./interfaces/IAirdrops.sol";
import "./interfaces/IAdmin.sol";
import "./interfaces/IERC20D.sol";

contract ION is ERC20, Ownable {

    //--------------------Other Contracts--------------------//

    IUniswapV2Router02 public uniswapV2Router;
    IAdmin public admin;
    IERC20D public USDC;

    address public devWallet;
    address public rewardsContract;


    //--------------------------Rewards-----------------------//

    uint256 public trickleChgReward;
    uint256 public superChgReward;
    uint256 public burnRebaseReward;
    uint256 public devReward;
    uint256 public liquidityReward;

    //--------------------------Time-based--------------------//

    uint256 public mintingTime = block.timestamp;
    uint256 public trickleBaseTime = block.timestamp;
    uint256 public maticDistribution = block.timestamp;
    uint256 public trickleTime = 300; // change before deployment
    uint256 public maticRewardTime = 600; // change before deployment
    uint256 public coolDownPeriod = 720; //change before deployment
    uint256 public buySellTime = block.timestamp + coolDownPeriod; //change before deployment

    //--------------------------check-if-required--------------//
    uint256 oneYearTime = 600; //should be removed before deployment
    

    //------------------------TaxPercentages------------------//

    uint256 public buyTax = 800; //8%
    uint256 public sellMaxTax = 1200; //12%
    uint256 public sellMinTax = 800; //8%
    uint256 public txTax = 300; // 3%
    uint256 public marketCapPer = 50; //0.5%
    uint256[5] public rewardsAmt; //100 bps
    

    //----------------------Thresholds-------------------------//

    uint256 public epochEndAmt;
    uint256 public epochCurrentAmt;
    uint256 public maxLimit = 50000 * 10 ** 18; //check before deployment

    //----------------------Booleans---------------------------//
    bool public enableSwapAndLiquify;
    bool public isDistributionEnabled;

    //-------------------------Contants-----------------------//

    uint256 public constant PCT_BASE = 10000;


    //-------------------------Structs----------------------//

    struct Taxes {
        uint256 individualBuy;
        uint256 individualSell;
        uint256 individualTx;
    }

    struct UserLimit {
        uint startTime;
        uint amount;
    }


    //-------------------------Mappings----------------------//

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => Taxes) public taxes;
    mapping(address => bool) public isPair;
    mapping(address => UserLimit) public userLimits;

    receive() external payable {}

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address user1,
        address _router,
        address _owner,//should be multi-sig
        address _admin,
        address _devWallet,
        address _rewardsContract,
        IERC20D USDC_
    ) ERC20(name_, symbol_) {
        admin = IAdmin(_admin);
        transferOwnership(_owner);
        _mint(user1, totalSupply_/2 );
        _mint(_owner, totalSupply_/2 );
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        isPair[uniswapV2Pair] = true;
        devWallet = _devWallet;
        rewardsContract = _rewardsContract;
        USDC = USDC_;
        rewardsAmt = [3000,1500,1500,3000,1000];
        isDistributionEnabled = true;
        enableSwapAndLiquify = true;
    }

    //---------------------------modifiers------------------------//

    modifier validation(address _address) {
        require(_address != address(0), "ION: Zero");
        _;
    }

    //---------------------------Admin-setters------------------------//

    function whitelistPair(address _newPair) external onlyOwner validation(_newPair) {
        isPair[_newPair] = true;
    }


    function setEnableSwapAndLiquify(bool _bool) external onlyOwner {
        enableSwapAndLiquify = _bool;
    }

    function setMaxLimit(uint256 _value) external onlyOwner {
        maxLimit = _value;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setRewards(uint256[5] calldata _rewardsAmt) public onlyOwner {
        uint total;
        for(uint8 i=0; i < _rewardsAmt.length; i++){
            total += _rewardsAmt[i];
        }
        require(total == PCT_BASE);
        rewardsAmt = _rewardsAmt;
    }

    function setBuyTax(uint256 _buyTax) public onlyOwner {
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellMaxTax, uint256 _sellMinTax)
        public
        onlyOwner
    {
        require(_sellMaxTax>_sellMinTax,"ION: Invalid");
        sellMaxTax = _sellMaxTax;
        sellMinTax = _sellMinTax;
    }

    function setTxTax(uint256 _txTax) public onlyOwner {
        txTax = _txTax;
    }

    function setTrickleChgTime(uint256 _time) external onlyOwner {
        trickleTime = _time;
    }

    function setMaticRewardTime(uint256 _time) external onlyOwner {
        maticRewardTime = _time;
    }

     function setRewardsContract(address _address) public onlyOwner validation(_address) {
        rewardsContract = _address;
    }

    function setDevWallet(address _address)
        public
        validation(_address)
        onlyOwner
    {
        devWallet = _address;
    }

    function setAdminContract(IAdmin _newAdmin) external onlyOwner validation(address(_newAdmin)) {
        admin = _newAdmin;
    }

    function setRouter(IUniswapV2Router02 _newRouter) external onlyOwner validation(address(_newRouter)) {
        uniswapV2Router = _newRouter;
    }

    function setStableCoin(IERC20D _stableCoin) external onlyOwner validation(address(_stableCoin)) {
        USDC = _stableCoin;
    }

    function setMarketCapPercent(uint256 _percent) public onlyOwner {
        marketCapPer = _percent;
    }

    function setDistributionStatus(bool _status) public onlyOwner {
        isDistributionEnabled = _status;
    }

    function setCoolDownPeriod(uint _newValue) external onlyOwner {
        coolDownPeriod = _newValue;
    }

    function mint(address to, uint256 percent) public onlyOwner {
            require(block.timestamp > mintingTime + oneYearTime);//change this to 365 days
            require(percent <= (PCT_BASE / 10));
            uint256 mintAmount = (percent * totalSupply() )/ PCT_BASE;
            _mint(to, mintAmount);
            mintingTime = block.timestamp;
    }

    function removeOtherERC20Tokens(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20D(_tokenAddress).balanceOf(address(this));
        IERC20D(_tokenAddress).transfer(devWallet, balance);
        uint256 bal = address(this).balance;

        if (bal > 0) {
            payable(devWallet).transfer(bal);
        }
    }

    //---------------------------getters------------------------//

    function getTokenPrice() public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = address(USDC);  //Todo change this address for mainnet
        uint256 tokenPrice = uniswapV2Router.getAmountsOut(10**18, path)[2];
        return tokenPrice;
    }

    function marketCap() public view returns (uint256) {
        return (totalSupply() * getTokenPrice()) / 10 ** 18;
    }

    function checkEpoch() public view returns (bool) {
        return epochCurrentAmt > epochEndAmt ? true : false;
    }

    //---------------------Internal-functions-------------------//

    function _setEpoch() internal {
        _setEpochEndAmt();
        buySellTime = block.timestamp + coolDownPeriod;
        epochCurrentAmt = 0;
    }

    function _setEpochEndAmt() internal {
        epochEndAmt = (marketCap() * marketCapPer) / (PCT_BASE);
    }

    function _tax(uint256 taxAmount_) internal {
        trickleChgReward += (taxAmount_ * rewardsAmt[0]) / PCT_BASE;
        superChgReward += (taxAmount_ * rewardsAmt[1]) / PCT_BASE;
        burnRebaseReward += (taxAmount_ * rewardsAmt[2]) / PCT_BASE;
        devReward += (taxAmount_ * rewardsAmt[3]) / PCT_BASE;

        if (rewardsAmt[4] > 0) {
            liquidityReward += (taxAmount_ * rewardsAmt[4]) / PCT_BASE;
        }
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual override{
        if(block.timestamp >= buySellTime && epochCurrentAmt == 0 ){
                // ISuperCharge(admin.superCharge()).startEpoch();
        }
        
        if (
            _isExcludedFromFee[_sender] ||
            _isExcludedFromFee[_recipient]
        ) {
            super._transfer(_sender, _recipient, _amount);
            return;
        }

        uint256 taxAmount;
        uint256 remAmount;
        
        if (isPair[_sender]) {
            // buy
            //Condition for no buy tax deduction

            if (epochEndAmt == 0) {
                _setEpochEndAmt();
            }

            if (block.timestamp <= buySellTime) {
                super._transfer(_sender, _recipient, _amount);
                return;
            } else {
                taxAmount = _calculateBuyTax(_recipient, _amount);                
            }
        } else if (isPair[_recipient]) {
            // sell
            if (epochEndAmt == 0) {
                _setEpochEndAmt();
            }

            taxAmount = _calculateSellTax(_sender, _amount);
            _checkSellLimit(_sender,_amount);
            
        } else {
            // if sender & receiver is not equal to pair address // 3% ta
            taxAmount = _calculateTxTax(_sender, _amount);
        }

        remAmount = _amount - taxAmount;
        _tax(taxAmount);

        if (isPair[_sender] || isPair[_recipient]) {
            epochCurrentAmt += ((_amount * getTokenPrice()) / (10**18));
        } else {
            if (isDistributionEnabled) {
                _distributeAndLiquify();
            }
        }

        
        super._transfer(_sender, address(this), taxAmount);
        super._transfer(_sender, _recipient, remAmount);

        if (isDistributionEnabled) {
            _distribution();
        }
    }

    function _calculateBuyTax(address _user, uint256 _amount) internal view returns (uint256 _taxAmount) {
        if (taxes[_user].individualBuy > 0) {
            _taxAmount =
                (_amount * taxes[_user].individualBuy) /
                PCT_BASE;
        } else {
            _taxAmount = (_amount * buyTax) / PCT_BASE;
        }
    }

    function _calculateSellTax(address _user, uint256 _amount) internal view returns (uint256 _taxAmount) {
        uint256 diffPer = (sellMaxTax - sellMinTax);
        uint256 currentAmtPct = ((epochCurrentAmt * PCT_BASE) /
                epochEndAmt);
        uint256 currUserTax;
        if(block.timestamp <= buySellTime){
            currUserTax = sellMaxTax;
        } else {
            currUserTax = (sellMaxTax -((currentAmtPct * diffPer)) /PCT_BASE);
        }
        if (taxes[_user].individualSell > 0) {
            _taxAmount = (_amount * taxes[_user].individualSell);
        } else {
            _taxAmount = (_amount * currUserTax) / PCT_BASE;
        }
    }

    function _calculateTxTax(address _user, uint256 _amount) internal view returns (uint256 _taxAmount) {
        if (taxes[_user].individualTx > 0) {
                _taxAmount =
                    (_amount * taxes[_user].individualTx) /
                    PCT_BASE;
            } else {
                _taxAmount = (_amount * txTax) / PCT_BASE;
            }
    }

    function _checkSellLimit(address user, uint transactAmount) internal{
        if (userLimits[user].startTime + 600 < block.timestamp) { //change this to 24 hours before deployment
            require(transactAmount <= maxLimit, "ION: max");
            userLimits[user] = UserLimit(block.timestamp, transactAmount);
        } else {
            require((maxLimit - userLimits[user].amount) >= transactAmount, "ION: max");
            userLimits[user].amount += transactAmount;
        }
    }

    function _distribution() internal {
        if (checkEpoch()) {
            if (superChgReward != 0 || burnRebaseReward != 0) {
                _processSuperchargeAndBurn();
            }
            _setEpoch();
        }

        if (block.timestamp >= trickleBaseTime + trickleTime) {
          _processTrickleAndDevRewards();
        }
    }

    function _distributeAndLiquify() internal {
        if(block.timestamp >= maticDistribution + maticRewardTime) {
            maticDistribution = block.timestamp;
            // IAirdrops(admin.airdrop()).distributionMatic();

            //swap and liquify
            if(enableSwapAndLiquify && (liquidityReward > 0)) {
                _swapAndLiquify();
            }
        }
    }

    function _processSuperchargeAndBurn() internal {
        // super._transfer(address(this), admin.superCharge(), superChgReward); // to stakers (rebase 15%)
        _burn(address(this), burnRebaseReward);
        // ISuperCharge(admin.superCharge()).endEpoch(superChgReward);
        super._transfer(address(this), devWallet, superChgReward);
        superChgReward = 0;
        burnRebaseReward = 0;
    }

    function _swapAndLiquify() internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uint256 swapAmount = liquidityReward/2;
        _approve(address(this), address(uniswapV2Router), 2**250);
        uint256 prevBal = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp+3600);
        if (address(this).balance > prevBal) {
            uint256 maticAmount = address(this).balance - prevBal;
             uniswapV2Router.addLiquidityETH{value:maticAmount}(address(this), swapAmount, 0, 0, address(this), block.timestamp+3600);
            liquidityReward = 0;
        }
       
    }

    function _processTrickleAndDevRewards() internal {
        // super._transfer(address(this), rewardsContract, trickleChgReward); // to Reward contract
        super._transfer(address(this), devWallet, devReward); // to marketing wallet
        trickleBaseTime = block.timestamp;
        //   IAirdrops(admin.airdrop()).distributionION(trickleChgReward);
        super._transfer(address(this), devWallet, trickleChgReward);
        trickleChgReward = 0;
        devReward = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IUniswapV2Factory {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IUniswapV2Pair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface ISuperCharge {

    function userDetails(address) external returns(uint,bool);
    function superChargeRewards(uint) external returns(uint,uint);
    function superChargeCount() external returns(uint);
    function setUserStateWithDeposit(address user, uint amount) external;
    function setUserStateWithWithdrawal(address user, uint amount) external;
    function canClaim(address) external returns(bool);
    function claimSuperCharge(address user) external;
    function startEpoch() external;
    function endEpoch(uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * @title IStaking.
 * @dev interface for staking
 * with params enum and functions.
 */
interface IAirdrops {
    function depositAssets(address, uint256, uint256) external payable;
    function setShareForMaticReward(address, uint256) external;
    function userPendingMatic(address user, uint amount) external;
    function pushIONAmount(uint _amount) external;
    function withdrawION(address user, uint _amount) external;
    function setShareForIONReward (address user,uint _prevLock, uint _amount) external; 
    function userPendingION(address user) external;
    function setTotalMatic(uint _amount) external;
    function distributionION(uint amount) external;
    function distributionMatic() external;
    function setMarketingWallet(address _address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ITokenSale.sol";

/**
 * @title IAdmin.
 * @dev interface of Admin contract
 * which can set addresses for contracts for:
 * airdrop, token sales maintainers, staking.
 * Also Admin can create new pool.
 */
interface IAdmin is IAccessControl {
    function getParams(address)
        external
        view
        returns (ITokenSale.Params memory);

    function airdrop() external returns (address);

    function tokenSalesM(address) external returns (bool);

    function blockClaim(address) external returns (bool);

    function tokenSales(uint256) external returns (address);

    function masterTokenSale() external returns (address);

    function stakingContract() external returns (address);

    function setMasterContract(address) external;

    function setAirdrop(address _newAddress) external;

    function setStakingContract(address) external;

    function createPool(ITokenSale.Params calldata _params) external;

    function getTokenSales() external view returns (address[] memory);

    function wallet() external view returns (address);

    function addToBlackList(address, address[] memory) external;

    function blacklist(address, address) external returns (bool);

    function superCharge() external returns(address);

    function setSuperCharge(address) external;

    /**
     * @dev Emitted when pool is created.
     */
    event CreateTokenSale(address instanceAddress);
    /**
     * @dev Emitted when airdrop is set.
     */
    event SetAirdrop(address airdrop);
}

// SPDX-License-Identifier: UNLICENSED



pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20D is IERC20 {
    function decimals() external returns (uint8);
    function _taxFee() external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: UNLICENSED


/**
 * @title ITokenSale.
 * @dev interface of ITokenSale
 * params structure and functions.
 */
pragma solidity ^0.8.4;

interface ITokenSale {

    struct Staked {
        uint128 amount;
        uint120 share;
        bool claimed;
    }

    enum Epoch {
        Incoming,
        Private,
        Finished
    }

    /**
     * @dev describe initial params for token sale
     * @param totalSupply set total amount of tokens. (Token decimals)
     * @param privateStart set starting time for private sale.
     * @param privateEnd set finish time for private sale.
     * @param privateTokenPrice set price for private sale per token in $ (18 decimals).
     * @param airdrop - amount reserved for airdrop
     */
    struct Params {
        uint96 totalSupply; //MUST BE 10**18;
        uint32 privateStart;
        uint96 privateTokenPrice; // MUST BE 10**18 in $  
        uint32 privateEnd;
    }

    struct State {
        uint128 totalPrivateSold;
        uint128 totalSupplyInValue;
    }

 
    /**
     * @dev initialize implementation logic contracts addresses
     * @param _stakingContract for staking contract.
     * @param _admin for admin contract.
     */
    function initialize(
        Params memory params,
        address _stakingContract,
        address _admin
    ) external;

    /**
     * @dev claim to sell tokens in airdrop.
     */
    // function claim() external;

    /**
     * @dev get banned list of addresses from participation in sales in this contract.
     */
    function epoch() external returns (Epoch);
    function destroy() external;
    function checkingEpoch() external;
    function totalTokenSold() external view returns (uint128);
    function giftTier(address[] calldata users, uint256[] calldata tiers) external;
    function stakes(address)
        external
        returns (
            uint128,
            uint120,
            bool
        );

    function takeLocked() external;
    function removeOtherERC20Tokens(address) external;
    function canClaim(address) external returns (uint120, uint256);
    function takeUSDCRaised() external;

    event DepositPrivate(address indexed user, uint256 amount, address instance);
    event Claim(address indexed user, uint256 change);
    event TransferAirdrop(uint256 amount);
    event TransferLeftovers(uint256 earned);
    event ERC20TokensRemoved(address _tokenAddress, address sender, uint256 balance);
    event RaiseClaimed(address _receiver, uint256 _amountInBUSD);
}