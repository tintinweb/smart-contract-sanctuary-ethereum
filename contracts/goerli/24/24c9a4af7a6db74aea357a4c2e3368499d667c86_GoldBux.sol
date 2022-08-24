//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

contract GoldBux is ERC20, ERC20Burnable, Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    event Claimed(address account, uint256 amount);
    event Deposited(address account, uint256 amount);
    event Airdropped(address account, uint256 amount);
    event Burned(uint256 amount);

    // ECDSA signer
    address public claimSigner;

    // tax related
    uint256 public buyTax = 5;
    uint256 public sellTax = 10;
    bool public taxEnabled = false;
    mapping(address => bool) private taxExempt;
    mapping(address => bool) private dexPairs;
    uint256 public collectedTax = 0;
    address public devWallet;

    // limits
    bool public paused = false;
    bool public limitsEnabled = true;
    bool public tradingEnabled = false;
    uint256 public tradingStartBlock;
    bool public transferDelayEnabled = true;
    uint256 public maxTransactionAmount;
    uint256 public maxPerWallet;
    mapping(address => bool) private maxExempt;
    mapping(address => uint256) private lastTransferBlock;

    // blacklisted
    mapping(address => bool) private blacklisted;

    // on chain storage
    mapping(uint256 => bool) private usedNonces;

    constructor(address devAddress, address signer) ERC20("GoldBux", "GDBX") {
        devWallet = devAddress;
        claimSigner = signer;
        _mint(address(this), 1_750_000 * 1e18);
        _mint(devWallet, 750_000 * 1e18);

        // contract and owners are tax exempt
        taxExempt[address(this)] = true;
        taxExempt[devWallet] = true;
        maxExempt[address(this)] = true;
        maxExempt[devWallet] = true;

        // limits
        maxTransactionAmount = totalSupply() * 30 / 10000; // 0.3%
        maxPerWallet = totalSupply() * 100 / 10000; // 1%
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setSigner(address signer) external onlyOwner {
        claimSigner = signer;
    }

    function setDevWallet(address account) external onlyOwner {
        devWallet = account;
    }

    ////////////////
    /// Claiming ///
    ////////////////

    /// @dev claim $GoldBux
    function claim(uint256 amount, uint256 nonce, uint256 expires, bytes memory signature) external {
        require(!paused, "Paused");
        require(!usedNonces[nonce], "Nonce already used");
        require(amount <= balanceOf(address(this)), "Not enough $GoldBux left");
        require(block.timestamp < expires, "Claim window expired");

        // verify signature
        bytes32 msgHash = keccak256(abi.encodePacked(_msgSender(), nonce, expires, amount));
        require(isValidSignature(msgHash, signature), "Invalid signature");
        usedNonces[nonce] = true;

        _transfer(address(this), _msgSender(), amount);
        emit Claimed(_msgSender(), amount);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == claimSigner;
    }

    function deposit(uint256 amount) external {
        require(!paused, "Paused");
        _transfer(_msgSender(), address(this), amount);
        emit Deposited(_msgSender(), amount);
    }

    function airdrop(address account, uint256 amount) external onlyOwner {
        _transfer(address(this), account, amount);
        emit Airdropped(account, amount);
    }

    function burnSupply(uint256 amount) external onlyOwner {
        _burn(address(this), amount);
        emit Burned(amount);
    }

    //////////////
    /// LIMITS ///
    //////////////

    function setLimitsEnabled(bool enabled) external onlyOwner {
        limitsEnabled = enabled;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
        tradingStartBlock = block.number;
    }

    function pauseTrading() external onlyOwner {
        tradingEnabled = false;
    }

    function setMaxTransactionAmount(uint256 amount) external onlyOwner {
        require(amount >= ((totalSupply() * 2) / 1000), "Cannot set lower than 0.2%");
        maxTransactionAmount = amount;
    }

    function setMaxPerWallet(uint256 max) external onlyOwner {
        require(max >= ((totalSupply() * 2) / 1000), "Cannot set lower than 0.2%");
        maxPerWallet = max;
    }

    function addBlacklisted(address[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklisted[accounts[i]] = true;
        }
    }

    function removeBlacklisted(address[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklisted[accounts[i]] = false;
        }
    }

    function isBlacklisted(address account) public view virtual returns(bool) {
        return blacklisted[account];
    }

    function addMaxExempt(address[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            maxExempt[accounts[i]] = true;
        }
    }

    function removeMaxExempt(address[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            maxExempt[accounts[i]] = false;
        }
    }

    function isMaxExempt(address account) public view virtual returns(bool) {
        return maxExempt[account];
    }

    ///////////////////
    /// TAX RELATED ///
    ///////////////////

    function setTax(bool enabled, uint256 buyPercentage, uint256 sellPercentage) external onlyOwner {
        require(buyPercentage <= 20, "Buy tax should be less than or equal 20%");
        require(sellPercentage <= 20, "Sell tax should be less than or equal 20%");
        taxEnabled = enabled;
        buyTax = buyPercentage;
        sellTax = sellPercentage;
    }

    function addTaxExempt(address[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            taxExempt[accounts[i]] = true;
        }
    }

    function removeTaxExempt(address[] memory accounts) external onlyOwner {
        require(accounts.length > 0, "No accounts");
        for (uint256 i = 0; i < accounts.length; i++) {
            taxExempt[accounts[i]] = false;
        }
    }

    function isTaxExempt(address account) public view virtual returns(bool) {
        return taxExempt[account];
    }

    function setDexPair(address pair, bool enabled) external onlyOwner {
        dexPairs[pair] = enabled;
    }

    function isDexPairEnabled(address pair) public view virtual returns(bool) {
        return dexPairs[pair];
    }

    // @dev override transfer so we can implement limits and taxes on buys/sells on DEX pairs
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(to != address(0xdead), "Transfer to dead address");
        require(balanceOf(from) >= amount, "Transfer amount exceeds balance");
        require(!blacklisted[from] && !blacklisted[to], "Blacklisted");

        // bot protection limits
        if (limitsEnabled && from != owner() && to != owner()) {
            if (!tradingEnabled) {
                require(taxExempt[from] || taxExempt[to], "Trading is not active");
            }

            require(block.number > tradingStartBlock, "0 block blackslist");

            if (transferDelayEnabled && !dexPairs[to]) {
                require(lastTransferBlock[tx.origin] < block.number, "One purchase per block allowed");
                lastTransferBlock[tx.origin] = block.number;
            }

            // buy/sell/transfer limits
            // when buying
            if (dexPairs[from] && !maxExempt[to]) {
                require(amount <= maxTransactionAmount, "Amount exceeds the max");
                require(amount + balanceOf(to) <= maxPerWallet, "Max per wallet exceeded");
            }
            // when selling
            else if (dexPairs[to] && !maxExempt[from]) {
                require(amount <= maxTransactionAmount, "Amount exceeds the max");
            }
            // when transferring
            else if (!maxExempt[to]) {
                require(amount + balanceOf(to) <= maxPerWallet, "Max per wallet exceeded");
            }
        }

        if (taxEnabled) {
            uint256 tax = 0;
            // buy
            if (dexPairs[from] && !taxExempt[to] && buyTax > 0) {
                tax = amount.mul(buyTax).div(100);
            }
            // sell
            else if (dexPairs[to] && !taxExempt[from] && sellTax > 0) {
                tax = amount.mul(sellTax).div(100);
            }

            if (tax > 0) {
                super._transfer(from, address(this), tax);
                amount -= tax;
                collectedTax += tax;
            }
        }

        super._transfer(from, to, amount);
    }

    // @dev withdraw collected tax to dev wallet
    function withdrawTax() external onlyOwner {
        require(collectedTax > 0, "No tax to withdraw");
        require(devWallet != address(0), "Dev wallet not set");
        // use parent transfer to avoid taxes in case dev wallet is not tax exempt
        super._transfer(address(this), devWallet, collectedTax);
        collectedTax = 0;
    }
}