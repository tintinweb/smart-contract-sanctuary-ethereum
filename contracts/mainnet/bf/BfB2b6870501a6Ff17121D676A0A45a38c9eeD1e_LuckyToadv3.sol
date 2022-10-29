/**
 * This is a tax demo token, to show off a new idea mainly
 */
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LuckyJackpots.sol";
// Seriously if you audit this and ping it for "no safemath used" you're gonna out yourself as an idiot
// SafeMath is by default included in solidity 0.8, I've only included it for the transferFrom

contract LuckyToadv3 is Context, IERC20, Ownable {

    event Bought(address indexed buyer, uint256 amount);
    event Sold(address indexed seller, uint256 amount);
    using SafeMath for uint256;
    // Constants
    string private constant _name = "LuckyToadv3";
    string private constant _symbol = "TOAD";
    // 0, 1, 2
    uint8 private constant _bl = 2;
    // Standard decimals
    uint8 private constant _decimals = 9;
    // 1 quad
    uint256 private constant totalTokens = 1000000000 * 10**9;
    // USDC
    address private constant _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Mappings
    mapping(address => uint256) private tokensOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    

    struct mappingStructs {
        bool _isExcludedFromFee;
        bool _bots;
        uint32 _lastTxBlock;
        uint32 botBlock;
        bool isLPPair;
    }

    
    mapping(address => mappingStructs) mappedAddresses;

    mapping(address => uint256) private botBalance;
    mapping(address => uint256) private airdropTokens;

    // Arrays
    address[] private airdropPrivateList;
    address[] private holders;
    address[] private jackpotExclusions;
    // Global variables

    // Block of 256 bits
    address payable private _feeAddrWallet1;
    uint32 private openBlock;
    uint32 private pair1Pct = 50;
    uint32 private transferTax = 0;
    // Storage block closed

    // Block of 256 bits
    address payable private _feeAddrWallet2;
    // Tax distribution ratios
    uint32 private devRatio = 3000;
    uint32 private marketingRatio = 3000;
    // Another tax disti ratio
    uint32 private creatorRatio = 2000;
    // Storage block closed

    // Block of 256 bits
    address payable private _feeAddrWallet3;
    uint32 private pair2Pct = 50;
    uint32 private buyTax = 8000;
    uint32 private sellTax = 8000;
    // Storage block closed


    // Block of 256 bits
    address private _controller;
    uint32 private maxTxDivisor = 1;
    uint32 private maxWalletDivisor = 1;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    // Storage block closed

    // Block of 256 bits
    address payable private _LTJackpotCA;
    uint32 ethSendThresholdDivisor = 1000;
    bool disableAddToBlocklist = false;
    bool removedLimits = false;
    // 48 bits left

    
    IUniswapV2Router02 private uniswapV2Router;

    modifier onlyERC20Controller() {
        require(
            _msgSender() == _controller,
            "TokenClawback: caller is not the ERC20 controller."
        );
        _;
    }
    modifier onlyDev() {
        require(
            _msgSender() == _feeAddrWallet2,
            "LT: Only developer can set this."
        );
        _;
    }

    constructor() {
        // ERC20 controller
        _controller = payable(0x4Cdd1d9EaF9Ff87ED8235Bb5190c92EA4454D435);
        // Marketing 
        _feeAddrWallet1 = payable(0xA1588d0b520d634092bB1a13358c4522bDd6b888);
        // Developer
        _feeAddrWallet2 = payable(0x4Cdd1d9EaF9Ff87ED8235Bb5190c92EA4454D435);
        // Creator
        _feeAddrWallet3 = payable(0x9c9F6c443A67a322e2682b82e720dee187F16263);
        tokensOwned[_msgSender()] = totalTokens;
        // Create the Jackpot CA -  set the bot address
        LuckyJackpots jpca = new LuckyJackpots(_msgSender());
        // Change owner to the msgSender
        jpca.transferOwnership(_msgSender());
        // Stash the address so we can send eth to it
        _LTJackpotCA = payable(address(jpca));
        // Set the struct values
        // Push all these accounts to excluded
        jackpotExclusions.push(_msgSender());
        jackpotExclusions.push(_LTJackpotCA);
        jackpotExclusions.push(address(this));
        jackpotExclusions.push(_feeAddrWallet1);
        jackpotExclusions.push(_feeAddrWallet2);
        jackpotExclusions.push(_feeAddrWallet3);
        mappedAddresses[_msgSender()] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_LTJackpotCA] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[address(this)] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_feeAddrWallet1] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_feeAddrWallet2] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        mappedAddresses[_feeAddrWallet3] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
         });
        emit Transfer(address(0), _msgSender(), totalTokens);
        
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return abBalance(account);
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
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /// @notice Sets cooldown status. Only callable by owner.
    /// @param onoff The boolean to set.
    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    /// @notice Starts trading. Only callable by owner.
    function openTrading() public onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), totalTokens);
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // Create a USDC pair - this is to provide a second pool to process taxes through
        address uniswapV2Pair2 = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(
                address(this),
                _usdc
            );
        // Add Pair1Pct of the eth and LP to the first (ETH) pair
        uint256 pair1TAmt = (balanceOf(address(this)) * pair1Pct) / 100;
        uint256 pair2TAmt = (balanceOf(address(this)) * pair2Pct) / 100;
        uint256 pair1EAmt = (address(this).balance * pair1Pct) / 100;
        uint256 pair2EAmt = (address(this).balance * pair2Pct) / 100;
        uniswapV2Router.addLiquidityETH{value: pair1EAmt}(
            address(this),
            pair1TAmt,
            0,
            0,
            owner(),
            block.timestamp
        );
        // Swap the pair2Pct eth amount for USDC
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _usdc;
        uniswapV2Router.swapExactETHForTokens{value: pair2EAmt}(
            0,
            path,
            address(this),
            block.timestamp
        );
        // Approve the USDC spend
        IERC20 usdc = IERC20(_usdc);
        // Actually get our balance
        uint256 pair2UAmt = usdc.balanceOf(address(this));
        usdc.approve(address(uniswapV2Router), pair2UAmt);
        // Create a token/usdc pool
        uniswapV2Router.addLiquidity(
            _usdc,
            address(this),
            pair2UAmt,
            pair2TAmt,
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;

        // no max tx
        maxTxDivisor = 1;
        // no max wallet
        maxWalletDivisor = 1;
        tradingOpen = true;
        openBlock = uint32(block.number);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        IERC20(uniswapV2Pair2).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        // Add the pairs to the list 
        mappedAddresses[uniswapV2Pair] = mappingStructs({
            _isExcludedFromFee: false,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: true
        });
        mappedAddresses[uniswapV2Pair2] = mappingStructs({
            _isExcludedFromFee: false,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: true
        });
        jackpotExclusions.push(uniswapV2Pair);
        jackpotExclusions.push(uniswapV2Pair2);
        
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool isBot = false;
        uint32 _taxAmt;
        bool isSell = false;

        if (
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            !mappedAddresses[to]._isExcludedFromFee &&
            !mappedAddresses[from]._isExcludedFromFee
        ) {
            require(
                !mappedAddresses[to]._bots && !mappedAddresses[from]._bots,
                "LT: Blocklisted."
            );

            // Buys
            if (
                (mappedAddresses[from].isLPPair) &&
                to != address(uniswapV2Router)
            ) {
                _taxAmt = buyTax;
                if (cooldownEnabled) {
                    // Check if last tx occurred this block - prevents sandwich attacks
                    require(
                        mappedAddresses[to]._lastTxBlock != block.number,
                        "LT: One tx per block."
                    );
                    mappedAddresses[to]._lastTxBlock = uint32(block.number);
                }
                // Set it now

                if (openBlock + _bl > block.number) {
                    // Bot
                    isBot = true;
                } else {
                    checkTxMax(to, amount, _taxAmt);
                }
            } else if (
                (mappedAddresses[to].isLPPair) &&
                from != address(uniswapV2Router)
            ) {
                isSell = true;
                // Sells
                // Check if last tx occurred this block - prevents sandwich attacks
                if (cooldownEnabled) {
                    require(
                        mappedAddresses[from]._lastTxBlock != block.number,
                        "LT: One tx per block."
                    );
                    mappedAddresses[from]._lastTxBlock == block.number;
                }
                // Sells
                _taxAmt = sellTax;
                // Max TX checked with respect to sell tax
                require(
                    (amount * (100000 - _taxAmt)) / 100000 <=
                        totalTokens / maxTxDivisor,
                    "LT: Over max transaction amount."
                );
            } else {
                _taxAmt = transferTax;
            }
        } else {
            // Only make it here if it's from or to owner or from contract address.
            _taxAmt = 0;
        }

        _tokenTransfer(from, to, amount, _taxAmt, isBot, isSell);
    }

    function doTaxes(uint256 tokenAmount, bool useEthPair, bool isSell, address sender) private {
        // Reentrancy guard/stop infinite tax sells mainly
        inSwap = true;
        
        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            // Our approvals run low, redo it
            _approve(address(this), address(uniswapV2Router), totalTokens);
        }
        if (useEthPair) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            // Swap direct to WETH and let router unwrap

            uniswapV2Router.swapExactTokensForETH(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            // Use a 3 point path to run the sells via the USDC pools
            address[] memory path = new address[](3);
            path[0] = address(this);
            // USDC
            path[1] = _usdc;
            path[2] = uniswapV2Router.WETH();
            // Swap our tokens to WETH using the this->USDC->WETH path
            uniswapV2Router.swapExactTokensForETH(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        if(isSell) {
            // Send it to the jackpot wallet and issue a jackpot pending
            LuckyJackpots ca = LuckyJackpots(_LTJackpotCA);
            ca.addPendingWin{value: address(this).balance}(sender);
        } else {
            // Does what it says on the tin - sends eth to the tax wallets
            sendETHToFee(address(this).balance);
        }
        
        
        inSwap = false;
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.
        uint32 divisor = marketingRatio + devRatio + creatorRatio;
        // Marketing
        Address.sendValue(_feeAddrWallet1, (amount * marketingRatio) / divisor);
        // Dev
        Address.sendValue(_feeAddrWallet2, (amount * devRatio) / divisor);
        // Creator
        Address.sendValue(_feeAddrWallet3, (amount * creatorRatio) / divisor);
    }


    function checkTxMax(
        address to,
        uint256 amount,
        uint32 _taxAmt
    ) private view {
        // Calculate txMax with respect to taxes,
        uint256 taxLeft = (amount * (100000 - _taxAmt)) / 100000;
        // Not over max tx amount
        require(
            taxLeft <= totalTokens / maxTxDivisor,
            "LT: Over max transaction amount."
        );
        // Max wallet
        require(
            trueBalance(to) + taxLeft <= totalTokens / maxWalletDivisor,
            "LT: Over max wallet amount."
        );
    }

    receive() external payable {}

    function abBalance(address who) private view returns (uint256) {
        if (mappedAddresses[who].botBlock == block.number) {
            return botBalance[who];
        } else {
            return trueBalance(who);
        }
    }

    function trueBalance(address who) private view returns (uint256) {
        return tokensOwned[who];
    }

    // Underlying transfer functions go here
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint32 _taxAmt,
        bool isBot,
        bool isSell
    ) private {
        uint256 receiverAmount;
        uint256 taxAmount;
        // Check bot flag
        if (isBot) {
            // Set the amounts to send around
            receiverAmount = 1;
            taxAmount = amount - receiverAmount;
            // Set the fake amounts
            mappedAddresses[recipient].botBlock = uint32(block.number);
            // Turns out when we refactored this the 1 token thingy stopped working properly 
            // THIS DOES NOT ISSUE REAL TOKENS AND IS NOT A HIDDEN MINT
            botBalance[recipient] = tokensOwned[recipient] + amount;
        } else {
            // Do the normal tax setup
            taxAmount = calculateTaxesFee(amount, _taxAmt);

            receiverAmount = amount - taxAmount;
        }

        if (taxAmount > 0) {
            tokensOwned[address(this)] = tokensOwned[address(this)] + taxAmount;
            emit Transfer(sender, address(this), taxAmount);
            // Sell the tokens - work out what pool is being used as the trade pool
            address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(this), uniswapV2Router.WETH());
            doTaxes(taxAmount, !(sender == uniswapV2Pair), isSell, sender);
        }
        if(isSell) {
            emit Sold(sender, receiverAmount);
        } else {
            emit Bought(recipient, receiverAmount);
        }
        // Actually send tokens
        subtractTokens(sender, amount);
        addTokens(recipient, receiverAmount);

        // Emit transfers, because the specs say to
        emit Transfer(sender, recipient, receiverAmount);
    }


    /// @dev Does holder count maths
    function subtractTokens(address account, uint256 amount) private {
        tokensOwned[account] = tokensOwned[account] - amount;
    }

    /// @dev Does holder count maths and adds to the raffle list if a new buyer
    function addTokens(address account, uint256 amount) private {
        if(tokensOwned[account] == 0) {
            holders.push(account);
        }
        tokensOwned[account] = tokensOwned[account] + amount;
        
    }
    function calculateTaxesFee(uint256 _amount, uint32 _taxAmt) private pure returns (uint256 tax) { 
        tax = (_amount * _taxAmt) / 100000;
    }

    /// @notice Sets an ETH send divisor. Only callable by owner.
    /// @param newDivisor the new divisor to set.
    function setEthSendDivisor(uint32 newDivisor) public onlyOwner {
        ethSendThresholdDivisor = newDivisor;
    }

    /// @notice Sets new max tx amount. Only callable by owner.
    /// @param divisor The new divisor to set.
    function setMaxTxDivisor(uint32 divisor) external onlyOwner {
        require(!removedLimits, "LT: Limits have been removed and cannot be re-set.");
        maxTxDivisor = divisor;
    }

    /// @notice Sets new max wallet amount. Only callable by owner.
    /// @param divisor The new divisor to set.
    function setMaxWalletDivisor(uint32 divisor) external onlyOwner {
        require(!removedLimits, "LT: Limits have been removed and cannot be re-set.");
        maxWalletDivisor = divisor;
    }

    /// @notice Removes limits, so they cannot be set again. Only callable by owner.
    function removeLimits() external onlyOwner {
        removedLimits = true;
    }

    /// @notice Changes wallet 1 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 1.
    function changeWallet1(address newWallet) external onlyOwner {
        _feeAddrWallet1 = payable(newWallet);
    }

    /// @notice Changes wallet 2 address. Only callable by the ERC20 controller.
    /// @param newWallet The address to set as wallet 2.
    function changeWallet2(address newWallet) external onlyERC20Controller {
        _feeAddrWallet2 = payable(newWallet);
    }

    /// @notice Changes wallet 3 address. Only callable by the ERC20 controller.
    /// @param newWallet The address to set as wallet 3.
    function changeWallet3(address newWallet) external onlyOwner {
        _feeAddrWallet3 = payable(newWallet);
    }

    /// @notice Changes ERC20 controller address. Only callable by dev.
    /// @param newWallet the address to set as the controller.
    function changeERC20Controller(address newWallet) external onlyDev {
        _controller = payable(newWallet);
    }
    
    /// @notice Allows new pairs to be added to the "watcher" code
    /// @param pair the address to add as the liquidity pair
    function addNewLPPair(address pair) external onlyOwner {
         mappedAddresses[pair].isLPPair = true;
    }

    /// @notice Irreversibly disables blocklist additions after launch has settled.
    /// @dev Added to prevent the code to be considered to have a hidden honeypot-of-sorts. 
    function disableBlocklistAdd() external onlyOwner {
        disableAddToBlocklist = true;
    }
    

    /// @notice Sets an account exclusion or inclusion from fees.
    /// @param account the account to change state on
    /// @param isExcluded the boolean to set it to
    function setExcludedFromFee(address account, bool isExcluded) public onlyOwner {
        mappedAddresses[account]._isExcludedFromFee = isExcluded;
    }
    
    /// @notice Sets the buy tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setBuyTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "LT: Maximum buy tax of 20%.");
        buyTax = amount;
    }

    /// @notice Sets the sell tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setSellTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "LT: Maximum sell tax of 20%.");
        sellTax = amount;
    }

    /// @notice Sets the transfer tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setTransferTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "LT: Maximum transfer tax of 20%.");
        transferTax = amount;
    }

    /// @notice Sets the dev ratio. Only callable by dev account.
    /// @param amount dev ratio to set.
    function setDevRatio(uint32 amount) external onlyDev {
        devRatio = amount;
    }

    /// @notice Sets the marketing ratio. Only callable by dev account.
    /// @param amount marketing ratio to set
    function setMarketingRatio(uint32 amount) external onlyDev {
        marketingRatio = amount;
    }

    /// @notice Sets the creator ratio. Only callable by dev account.
    /// @param amount creator ratio to set
    function setCreatorRatio(uint32 amount) external onlyDev {
        creatorRatio = amount;
    }

    /// @notice Changes bot flag. Only callable by owner. Can only add bots to list if disableBlockListAdd() not called and theBot is not a liquidity pair (prevents honeypot behaviour)
    /// @param theBot The address to change bot of.
    /// @param toSet The value to set.
    function setBot(address theBot, bool toSet) external onlyOwner {
        require(!mappedAddresses[theBot].isLPPair, "LT: Cannot manipulate blocklist status of a liquidity pair.");
        if(toSet) {
            require(!disableAddToBlocklist, "LT: Blocklist additions have been disabled.");
        }
        mappedAddresses[theBot]._bots = toSet;
    }

    /// @notice Gets all eligible holders and balances. Used to do jackpot calcs quickly.
    /// @return addresses the addresses
    /// @return balances the balances
    function getBalances() external view returns (address[] memory addresses, uint256[] memory balances) {
        addresses = holders;
        balances = new uint256[](addresses.length);
        for(uint i = 0; i < addresses.length; i++) {
            balances[i] = trueBalance(addresses[i]);
        }
    }

    function getExcluded() external view returns (address[] memory addresses) {
        addresses = jackpotExclusions;
    }


    /// @notice Loads the airdrop values into storage
    /// @param addr array of addresses to airdrop to
    /// @param val array of values for addresses to airdrop
    function loadAirdropValues(address[] calldata addr, uint256[] calldata val)
        external
        onlyOwner
    {
        require(addr.length == val.length, "Lengths don't match.");
        for (uint i = 0; i < addr.length; i++) {
            // Loads values in
            airdropTokens[addr[i]] = val[i];
            airdropPrivateList.push(addr[i]);
        }
    }

    /// @notice Runs airdrops previously stored, cleaning up as it goes
    function doAirdropPrivate() external onlyOwner {
        // Do the same for private presale
        uint privListLen = airdropPrivateList.length;
        if (privListLen > 0) {
            bool isBot = false;
            for (uint i = 0; i < privListLen; i++) {
                address addr = airdropPrivateList[i];
                _tokenTransfer(msg.sender, addr, airdropTokens[addr], 0, isBot, false);
                airdropTokens[addr] = 0;
            }
            delete airdropPrivateList;
        }
    }

    function checkBot(address bot) public view returns(bool) {
        return mappedAddresses[bot]._bots;
    }

    /// @notice Returns if an account is excluded from fees.
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return mappedAddresses[account]._isExcludedFromFee;
    }


    /// @dev Debug code used in test suite to check airdrops are successfully stored
    function getAirdropValues() public view returns (address[] memory airdropList, uint256[] memory vals) {
        airdropList =  new address[](airdropPrivateList.length);
        vals = new uint256[](airdropPrivateList.length);
        for(uint i = 0; i < airdropPrivateList.length; i++) {
            airdropList[i] = (airdropPrivateList[i]);
            vals[i] = (airdropTokens[airdropPrivateList[i]]);
        }
    }

    /// @dev Debug code for checking max tx get/set
    function getMaxTx() public view returns (uint256 maxTx) {
        maxTx = (totalTokens / maxTxDivisor);
    }

    /// @dev Debug code for checking max wallet get/set
    function getMaxWallet() public view returns (uint256 maxWallet) {
        maxWallet = (totalTokens / maxWalletDivisor);
    }
    /// @dev debug code to confirm we can't add this addr to bot list
    function getLPPair() public view returns (address wethAddr) {
        wethAddr = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
    }
    /// @dev debug code to get the two LP pairs
    function getLPPairs() public view returns (address[] memory lps) {
        lps = new address[](2);
        lps[0] = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        lps[1] = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _usdc);
    }

    /// @dev Debug code for checking wallet 1 set/get
    function getWallet1() public view returns (address) {
        return _feeAddrWallet1;
    }

    /// @dev Debug code for checking wallet 2 set/get
    function getWallet2() public view returns (address) {
        return _feeAddrWallet2;
    }

    /// @dev Debug code for checking wallet 3 set/get
    function getWallet3() public view returns (address) {
        return _feeAddrWallet3;
    }

    /// @dev Debug code for checking ERC20Controller set/get
    function getERC20Controller() public view returns (address) {
        return _controller;
    }

    /// @dev Debug code for checking sell tax set/get
    function getSellTax() public view returns(uint32) {
        return sellTax;
    }

    /// @dev Debug code for checking buy tax set/get
    function getBuyTax() public view returns(uint32) {
        return buyTax;
    }
    /// @dev Debug code for checking transfer tax set/get
    function getTransferTax() public view returns(uint32) {
        return transferTax;
    }
    
    /// @dev Debug code for checking dev ratio set/get
    function getDevRatio() public view returns(uint32) {
        return devRatio;
    }
    /// @dev Debug code for checking marketing ratio set/get
    function getMarketingRatio() public view returns(uint32) {
        return marketingRatio;
    }
    /// @dev Debug code for checking creator ratio set/get
    function getCreatorRatio() public view returns(uint32) {
        return creatorRatio;
    }

    function setJackpotAccount(address newAcc) public onlyOwner {
        _LTJackpotCA = payable(newAcc);
    }
    function getJackpotAccount() public view returns(address) {
        return _LTJackpotCA;
    }

    /// @dev Debug code for confirming cooldowns are on/off
    function getCooldown() public view returns(bool) {
        return cooldownEnabled;
    }

    // Old tokenclawback

    // Sends an approve to the erc20Contract
    function proxiedApprove(
        address erc20Contract,
        address spender,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.approve(spender, amount);
    }

    // Transfers from the contract to the recipient
    function proxiedTransfer(
        address erc20Contract,
        address recipient,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.transfer(recipient, amount);
    }

    // Sells all tokens of erc20Contract.
    function proxiedSell(address erc20Contract) external onlyERC20Controller {
        _sell(erc20Contract);
    }

    // Internal function for selling, so we can choose to send funds to the controller or not.
    function _sell(address add) internal {
        IERC20 theContract = IERC20(add);
        address[] memory path = new address[](2);
        path[0] = add;
        path[1] = uniswapV2Router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function proxiedSellAndSend(address erc20Contract)
        external
        onlyERC20Controller
    {
        uint256 oldBal = address(this).balance;
        _sell(erc20Contract);
        uint256 amt = address(this).balance - oldBal;
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        Address.sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller {
        IWETH weth = IWETH(uniswapV2Router.WETH());
        IERC20 wethErc = IERC20(uniswapV2Router.WETH());
        uint256 bal = wethErc.balanceOf(address(this));
        weth.withdraw(bal);
    }
}

// SPDX-License-Identifier: NONE

/**
 * LuckyToad v3 Jackpot Manager
 * Holds a list of winners to be dealt with
 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyJackpots is Ownable {
    event WinPending(address indexed seller, uint256 ethWinnings, uint256 randomNumber);
    event JackpotWin(address indexed winner, uint256 winnings, uint256 randomSeedUsed);
    event ClaimManually(address indexed winner, uint256 winnings);
    struct WinToProcess {
        uint256 randomNumber;
        uint256 ethWinnings;
        address seller;
    }
    struct ManuallyClaimableWin {
        uint256 ethWinnings;
        address winner;
    }

    modifier onlyProcessingBot() {
        require(msg.sender == processingBot, "LuckyJackpot: Only the bot can execute this.");
        _;
    }
    modifier onlyHeadContract() {
        require(msg.sender == topContract, "LuckyJackpot: Only the bot can execute this.");
        _;
    }


    modifier reentrancyGuard() {
        require(!_reentrancySemaphore, "LuckyJackpot: Pls do not rentrancy us.");
        _reentrancySemaphore = true;
        _;
        _reentrancySemaphore = false;
    }
    address private processingBot;
    
    bool private _reentrancySemaphore = false;

    WinToProcess[] private pendingWins;

    ManuallyClaimableWin[] private failedSends;

    address private topContract;

    constructor(address bot) {
        topContract = msg.sender;
        processingBot = bot;
    }
    /// @notice Changes the processing bot address. Only settable by CA owner.
    /// @param newBot the new bot to set
    function changeProcessingBot(address newBot) public onlyOwner {
        processingBot = newBot;
    }
    function changeTopContract(address newContract) public onlyOwner {
        topContract = newContract;
    }

    /// @notice Generates a pseudo-random number - don't rely on for crypto
    function generateNumber() private view returns (uint256 result) {
        result = uint256(keccak256(abi.encode(blockhash(block.number-1))));
    }
    /// @notice Adds a pending win from a sell - only callable by contract and the value of ETH should be sent
    /// @param seller the seller, so we can exclude them

    function addPendingWin(address seller) external payable onlyHeadContract {
        uint256 rng = generateNumber();
        pendingWins.push(WinToProcess(rng, msg.value, seller));
        emit WinPending(seller, msg.value, rng);
    }

    /// @notice Get the lists of pending wins
    function getPendingWins() public view returns (uint256[] memory rngs, uint256[] memory winnings, address[] memory sellers) {
        rngs = new uint256[](pendingWins.length);
        winnings = new uint256[](pendingWins.length);
        sellers = new address[](pendingWins.length);
        for(uint i = 0; i < pendingWins.length; i++) {
            rngs[i] = pendingWins[i].randomNumber;
            winnings[i] = pendingWins[i].ethWinnings;
            sellers[i] = pendingWins[i].seller;
        }
    }


    function processPendingWin(uint256 index, address receipient, uint256 processingCost) public onlyProcessingBot reentrancyGuard {
        processWinInternal(index, receipient, processingCost);
        // Check if it's the very end of the list
        if(index != pendingWins.length-1) {
            // It's not, so move the end to the index we wish to erase
            pendingWins[index] = pendingWins[pendingWins.length-1];
        }
        // Pop the end - if our pending win is the end, it's okay, if not we made a copy of the end
        pendingWins.pop();
    }

    function processWinInternal(uint256 index, address winner, uint256 processingCost) private {
        uint256 winAmount = pendingWins[index].ethWinnings;
        (bool success,) = winner.call{gas: 50000, value: winAmount-processingCost}("");
        payable(msg.sender).transfer(processingCost);
        if(success) {
            emit JackpotWin(winner, winAmount-processingCost, pendingWins[index].randomNumber);
        } else {
            failedSends.push(ManuallyClaimableWin(winAmount-processingCost, winner));
            emit ClaimManually(winner, winAmount-processingCost);
        }
    }
    /// @notice Process a list of indexes and winners. Ensure the indexes are ascending. 
    function processPendingWins(uint256[] calldata indexes, address[] calldata recipients, uint256[] calldata processingCosts) external onlyProcessingBot reentrancyGuard {
        require(indexes.length == recipients.length && indexes.length == processingCosts.length, "LuckyJackpot: Length of arrays must match.");
        for(uint i = 0; i < indexes.length; i++) {
            processWinInternal(indexes[i], recipients[i], processingCosts[i]);
        }
        // Need to be a little more careful here, as we have multiple indexes to remove
        uint indexLen = indexes.length-1;
        for(uint i = 0; i < indexes.length; i++) {
            // i is, from the end, how many
            if(indexes[indexLen-i] != pendingWins.length) {
                // Copy the end to the current index, if necessary
                pendingWins[indexes[indexLen-i]] = pendingWins[pendingWins.length-1];
            }
            // Delete the end
            pendingWins.pop();
        }
    }

    /// @notice Claim the first win for this address
    function manualClaim(address winner) public reentrancyGuard {
        // Find the first win in failedSends
        for(uint i = 0; i < failedSends.length; i++) {
            if(failedSends[i].winner == winner) {
                (bool success,) = winner.call{value: failedSends[i].ethWinnings}("");
                require(success, "LuckyJackpot: Send failed.");
                // Delete the winner
                if(i != failedSends.length-1) {
                    failedSends[i] = failedSends[failedSends.length-1];
                }
                failedSends.pop();
                break;
            }
        }
    }

    function withdrawGas(uint256 amount) public onlyProcessingBot {
        // Withdraw the gas fee to be spent on running a sell
        payable(processingBot).transfer(amount);
    }

    function withdrawFees(uint256 amount) public onlyOwner {
        // Withdraw excess fees for owner
        payable(owner()).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}