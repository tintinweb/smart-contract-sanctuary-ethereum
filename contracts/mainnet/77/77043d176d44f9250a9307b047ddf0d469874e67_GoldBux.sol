//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ECDSA.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract GoldBux is ERC20, ERC20Burnable, Ownable, Pausable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    event Claimed(address account, uint256 amount);
    event Deposited(address account, uint256 amount);
    event Airdropped(address account, uint256 amount);
    event Burned(uint256 amount);

    // ECDSA signer
    address private signer;

    // tax related
    uint256 private buyTax = 5;
    uint256 private sellTax = 10;
    bool private taxEnabled = false;
    mapping(address => bool) private taxExempt;
    mapping(address => bool) private dexPairs;
    uint256 private collectedTax = 0;
    address private devWallet;

    // on chain storage
    mapping(uint256 => bool) private usedNonces;

    constructor(address devAddress, address signerAddress) ERC20("GoldBux", "GDBX") {
        devWallet = devAddress;
        signer = signerAddress;
        _mint(address(this), 1_750_000 * 1e18);
        _mint(devWallet, 750_000 * 1e18);

        // contract and owners are tax exempt
        taxExempt[address(this)] = true;
        taxExempt[devWallet] = true;
    }

    /// @dev claim $GoldBux, stores when token ids were last claimed, nonce is also stored to prevent replay attacks
    function claim(uint256 amount, uint256 nonce, uint256 expires, bytes memory signature) external whenNotPaused {
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
        return signedHash.recover(signature) == signer;
    }

    /// @dev deposits $GoldBux to contract and emits an event
    function deposit(uint256 amount) external whenNotPaused {
        _transfer(_msgSender(), address(this), amount);
        emit Deposited(_msgSender(), amount);
    }

    /// @dev airdrop $GoldBux to account
    function airdrop(address account, uint256 amount) external onlyOwner whenNotPaused {
        _transfer(address(this), account, amount);
        emit Airdropped(account, amount);
    }

    /// @dev burn supply
    function burnSupply(uint256 amount) external onlyOwner {
        _burn(address(this), amount);
        emit Burned(amount);
    }

    // @dev pause contract
    function pause() external onlyOwner {
        _pause();
    }

    // @dev unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // @dev set new signer
    function setSigner(address messageSigner) external onlyOwner {
        signer = messageSigner;
    }

    function getSigner() public view virtual returns (address) {
        return signer;
    }

    // @dev set dev wallet
    function setDevWallet(address account) external onlyOwner {
        devWallet = account;
    }

    function getDevWallet() public view virtual returns (address) {
        return devWallet;
    }

    ///////////////////
    /// TAX RELATED ///
    ///////////////////

    /// @dev set buy tax fee percentage
    function setBuyTax(uint256 percentage) external onlyOwner {
        require(percentage <= 20, "Buy tax should be less than or equal 20%");
        buyTax = percentage;
    }

    /// @dev get buy tax fee percentage
    function getBuyTax() public view virtual returns (uint256) {
        return buyTax;
    }

    /// @dev set sell tax fee percentage
    function setSellTax(uint256 percentage) external onlyOwner {
        require(percentage <= 20, "Sell tax should be less than or equal 20%");
        sellTax = percentage;
    }

    /// @dev get sell tax fee percentage
    function getSellTax() public view virtual returns (uint256) {
        return sellTax;
    }

    /// @dev enable/disable tax on buy/sell
    function setTaxEnabled(bool enabled) external onlyOwner {
        taxEnabled = enabled;
    }

    /// @dev get if tax is enabled for buy/sells
    function getTaxEnabled() public view virtual returns (bool) {
        return taxEnabled;
    }

    // @dev set tax exempt address (true to exempt, false to not be exempt)
    function setTaxExempt(address account, bool exempt) external onlyOwner {
        taxExempt[account] = exempt;
    }

    // @dev is address tax exempt
    function isTaxExempt(address account) public view virtual returns(bool) {
        return taxExempt[account];
    }

    // @dev set an AMM pair as enabled or not
    function setDexPair(address pair, bool enabled) external onlyOwner {
        dexPairs[pair] = enabled;
    }

    // @dev get if AMM pair is taxable
    function isDexPairEnabled(address pair) public view virtual returns(bool) {
        return dexPairs[pair];
    }

    // @dev override transfer so we can implement taxes on buys/sells on DEX pairs
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(balanceOf(from) >= amount, "Transfer amount exceeds balance");

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

    /// @dev get how much tax has been collected since it was last withdrawn
    function getCollectedTax() public view virtual returns(uint256) {
        return collectedTax;
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