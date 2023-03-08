/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract UniverzToken is IERC20Metadata, Ownable {
    event currentSalePhaseEvent(uint256 phaseNo);
    event percentDividerEvent(uint256 percentDivider);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    IERC20Metadata public exchangeToken;

    string private _name;
    string private _symbol;

    uint256[4] salePhasesPercentages;
    uint256[4] public salePhasePrices;
    uint256[4] public minPurchaseAmount;
    uint256 public currentSalePhase;
    uint256 public soldTokens;
    uint256 public saleCounter;

    uint256 public percentDivider;
    bool public buyingPaused;

    constructor() {
        _name = "Univerz";
        _symbol = "UNIV";

        exchangeToken = IERC20Metadata(
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        ); //USDT ADDRESS Ethereum Mainnet
        //https://etherscan.io/token/0xdac17f958d2ee523a2206206994597c13d831ec7
        _mint(msg.sender, 800_000_000 * (10**decimals())); //80% of one billion to owner wallet
        _mint(address(this), 200_000_000 * (10**decimals())); //20% of one billion for the sale
        percentDivider = 100_00;
        salePhasesPercentages = [500, 500, 500, 500]; //5 percent each
        minPurchaseAmount = [
            5 * (10**exchangeToken.decimals()),
            10 * (10**exchangeToken.decimals()),
            15 * (10**exchangeToken.decimals()),
            25 * (10**exchangeToken.decimals())
        ]; //5 usdt, 10 usdt , 15 usdt , 25 usdt ;
        salePhasePrices = [5000, 10000, 15000, 25000]; // 0.005 , 0.010, 0.015 , 0.025
    }

    function buyToken(uint256 _payAmount) public {
        require(
            !buyingPaused,
            "The buying is currently paused. Can't buy at this moment"
        ); // For disabling sale feature for temporily!.
        require(
            soldTokens < (totalSupply() * 2000) / percentDivider ||
                currentSalePhase == 4,
            "Sale  is Over!"
        ); // To check that is sale of token is sold out or not
        require(
            _payAmount >= minPurchaseAmount[currentSalePhase],
            "You cannot buy minimum token than limit of phase"
        ); //Limit buy check . For example 5 usdt and 1000 token is minimum token of that phase

        uint256 _amountOfTokens = getTokenAmount(_payAmount);
        saleCounter += _amountOfTokens;
        soldTokens += _amountOfTokens;
        if (
            (
                (currentSalePhase == 3)
                    ? saleCounter >=
                        ((totalSupply() *
                            salePhasesPercentages[currentSalePhase]) /
                            percentDivider) -
                            1
                    : saleCounter >=
                        (totalSupply() *
                            salePhasesPercentages[currentSalePhase]) /
                            percentDivider
            ) && currentSalePhase < 4
        ) {
            currentSalePhase++;
            saleCounter = 0;
        }

        require(
            _amountOfTokens <=
                ((totalSupply() * salePhasesPercentages[currentSalePhase]) /
                    percentDivider) -
                    saleCounter,
            " You cannot buy that amountin current phase.Because tokens are is sold out.Try to decrease the amount"
        );

        bool transferFromstatus = exchangeToken.transferFrom(
            msg.sender,
            address(this),
            _payAmount
        );
        require(
            transferFromstatus,
            "Token Buy Failed due to  exchange token transfer failed"
        );

        bool transferStatus = this.transfer(msg.sender, _amountOfTokens);
        require(transferStatus, "Token Buy Failed");
    }

    function currentPresaleSoldPercentage()
        external
        view
        returns (uint256 _percentage)
    {
        _percentage =
            (saleCounter * percentDivider * 100) /
            ((totalSupply() * salePhasesPercentages[currentSalePhase]) /
                percentDivider);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

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

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address recipent = msg.sender;
        _transfer(recipent, to, amount);
        return true;
    }

    function allowance(address sender, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[sender][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address recipent = msg.sender;
        _approve(recipent, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address sender = msg.sender;
        _approve(sender, spender, allowance(sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address sender = msg.sender;
        uint256 currentAllowance = allowance(sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;

            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _spendAllowance(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(sender, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(sender, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function getTokenAmount(uint256 _amount) public view returns (uint256) {
        return (_amount * 1e18) / salePhasePrices[currentSalePhase];
    }

    /** 
     To increase or decrease the price and change phase according to
     situation of market. like it acts as failsafe feature 
     **/

    function changeSalePhase(uint256 _phaseNo) external onlyOwner {
        require(_phaseNo >= 4, "Cannot be greater than four phases");
        currentSalePhase = _phaseNo;
        emit currentSalePhaseEvent(currentSalePhase);
    }

    /** 
     To pause tokenSale  according to
     situation. like it acts as failsafe feature 
     **/

    function pauseOrUnpauseBuying(bool _pause) external onlyOwner {
        buyingPaused = _pause;
    }

    function setSalePhasesPercentages(
        uint256[4] memory _percentages,
        uint256 _percentDivider
    ) external onlyOwner {
        salePhasesPercentages = _percentages;
        percentDivider = _percentDivider;
        emit percentDividerEvent(percentDivider);
    }

    function setMinAmountofPurchase(uint256[4] memory _minPurchaseAmount)
        external
        onlyOwner
    {
        minPurchaseAmount = _minPurchaseAmount;
    }

    /** 
        Used to withdraw stuck tokens from contract 
     **/

    function withdrawStuckToken(IERC20Metadata _token, uint256 _amount)
        external
        onlyOwner
    {
        bool transferStatus = _token.transfer(msg.sender, _amount);
        require(transferStatus, "Token Transfer Failed");
    }

    function withdrawReceivedTokensBySale() external onlyOwner {
        bool transferStatus = exchangeToken.transfer(
            msg.sender,
            exchangeToken.balanceOf(address(this))
        );
        require(transferStatus, "Token Transfer Failed");
    }

    function changeExchangeToken(IERC20Metadata _token) external onlyOwner {
        exchangeToken = _token;
    }
}