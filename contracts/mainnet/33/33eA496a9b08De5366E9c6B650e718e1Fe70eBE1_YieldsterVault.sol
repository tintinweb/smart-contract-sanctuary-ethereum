// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./storage/VaultStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract YieldsterVault is VaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event Response(address feeAddress, string message);
    event CallStatus(string message);

    /// @dev Function to upgrade the mastercopy of Yieldster Vault.
    /// @param _mastercopy Address of new mastercopy of Yieldster Vault.
    function upgradeMasterCopy(address _mastercopy) external {
        _isYieldsterGOD();
        (bool result, ) = address(this).call(
            abi.encodeWithSignature("changeMasterCopy(address)", _mastercopy)
        );
        revertDelegate(result);
    }

    /// @dev Function to set APS Address.
    /// @param _APContract Address of Yieldster APS contract.
    function setAPS(address _APContract) external {
        _isYieldsterGOD();
        APContract = _APContract;
    }

    /// @dev Function to toggle Emergency Break feature of the Vault.
    function toggleEmergencyBreak() external {
        _isYieldsterGOD();
        if (emergencyConditions == 1) emergencyConditions = 0;
        else if (emergencyConditions == 0) emergencyConditions = 1;
    }

    /// @dev Function to enable emergency exit.
    function enableEmergencyExit() external {
        _isYieldsterGOD();
        emergencyConditions = 2;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assetList[i] == eth) {
                uint256 tokenBalance = address(this).balance;
                if (tokenBalance > 0) {
                    address payable to = payable(emergencyVault);
                    // to.transfer replaced here
                    (bool success, ) = to.call{value: tokenBalance}("");
                    if (success == false) {
                        emit CallStatus("call failed");
                    }
                }
            } else {
                IERC20 token = IERC20(assetList[i]);
                uint256 tokenBalance = token.balanceOf(address(this));
                if (tokenBalance > 0) {
                    token.safeTransfer(emergencyVault, tokenBalance);
                }
            }
        }
    }

    /// @dev Function that checks if the user is whitelisted.
    function _isWhiteListed() private view {
        if (whiteListGroups.length == 0) {
            return;
        } else {
            for (uint256 i = 0; i < whiteListGroups.length; i++) {
                if (isWhiteListGroupPresent[whiteListGroups[i]]) {
                    if (
                        IWhitelist(IAPContract(APContract).whitelistModule())
                            .isMember(whiteListGroups[i], msg.sender)
                    ) {
                        return;
                    }
                }
            }
            revert("Only Whitelisted");
        }
    }

    /// @dev Function that is called once after vault creation to Register the Vault with APS.
    function registerVaultWithAPS() external onlyNormalMode {
        require(msg.sender == owner, "unauthorized");
        require(!vaultRegistrationCompleted, "Vault already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(vaultAdmin, whiteListGroups);
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _APContract Address of apcontract.
    /// @param _vaultAdmin Address of the Vault APS Manager.
    /// @param _emergencyVault Address of the emergency vault.
    function setup(
        address _APContract,
        address _vaultAdmin,
        address _emergencyVault
    ) external {
        require(!vaultSetupCompleted, "Vault already setup");
        vaultSetupCompleted = true;
        vaultAdmin = _vaultAdmin;
        APContract = _APContract;
        owner = _vaultAdmin;
        eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        emergencyVault = _emergencyVault;
        tokenBalances = new TokenBalanceStorage();
    }

    /// @dev Function to transfer ownership.
    /// @param _owner Address of the new owner.
    function transferOwnership(address _owner) external {
        require(msg.sender == owner, "unauthorized");
        owner = _owner;
    }

    /// @dev Function to add whiteListGroups.
    /// @param _whiteListGroups List of whiteListGroups to be added.
    function addWhiteListGroups(uint256[] memory _whiteListGroups) external {
        _isVaultAdmin();
        for (uint256 i = 0; i < _whiteListGroups.length; i++) {
            if (!isWhiteListGroupPresent[_whiteListGroups[i]]) {
                whiteListGroups.push(_whiteListGroups[i]);
                isWhiteListGroupPresent[_whiteListGroups[i]] = true;
            }
        }
    }

    /// @dev Function to remove whiteListGroups.
    /// @param _whiteListGroups List of whiteListGroups to be removed.
    function removeWhiteListGroups(uint256[] memory _whiteListGroups) external {
        _isVaultAdmin();
        for (uint256 i = 0; i < _whiteListGroups.length; i++) {
            isWhiteListGroupPresent[_whiteListGroups[i]] = false;
        }
    }

    /// @dev Function to set TokenDetails.
    /// @param _tokenName Token Name.
    /// @param _symbol Token Symbol.
    function setTokenDetails(string memory _tokenName, string memory _symbol)
        external
    {
        require(msg.sender == owner, "unauthorized");
        setupToken(_tokenName, _symbol);
    }

    /// @dev Function to set Slippage percentage of the vault.
    /// @param _slippage Slippage percentage.
    function setVaultSlippage(uint256 _slippage) external onlyNormalMode {
        require(msg.sender == vaultAdmin, "unauthorized");
        IAPContract(APContract).setVaultSlippage(_slippage);
    }

    /// @dev Function to manage the assets supported by the vaults.
    /// @param _enabledDepositAsset List of assets to be enabled in Deposit assets.
    /// @param _enabledWithdrawalAsset List of assets to be enabled in Withdrawal assets.
    /// @param _disabledDepositAsset List of assets to be disabled in Deposit assets.
    /// @param _disabledWithdrawalAsset List of assets to be disabled in Withdrawal assets.
    function setVaultAssets(
        address[] calldata _enabledDepositAsset,
        address[] calldata _enabledWithdrawalAsset,
        address[] calldata _disabledDepositAsset,
        address[] calldata _disabledWithdrawalAsset
    ) external onlyNormalMode {
        require(msg.sender == vaultAdmin, "unauthorized");
        IAPContract(APContract).setVaultAssets(
            _enabledDepositAsset,
            _enabledWithdrawalAsset,
            _disabledDepositAsset,
            _disabledWithdrawalAsset
        );
    }

    /// @dev Function to change the APS Manager of the Vault.
    /// @param _vaultAdmin Address of the new APS Manager.
    function changeVaultAdmin(address _vaultAdmin) external onlyNormalMode {
        require(
            IAPContract(APContract).yieldsterDAO() == msg.sender ||
                vaultAdmin == msg.sender,
            "unauthorized"
        );
        vaultAdmin = _vaultAdmin;
        IAPContract(APContract).changeVaultAdmin(_vaultAdmin);
    }

    /// @dev Function to set smart strategies to vault.
    /// @param _smartStrategyAddress Address of smart Strategy.
    /// @param _type Type of smart strategy.
    function setVaultSmartStrategy(address _smartStrategyAddress, uint256 _type)
        public
    {
        _isVaultAdmin();
        IAPContract(APContract).setVaultSmartStrategy(
            _smartStrategyAddress,
            _type
        );
    }

    /// @dev Function to set threshold Vaule.
    /// @param _threshold minimum threshold of an asset in vault.
    function setThreshold(uint256 _threshold) external {
        _isVaultAdmin();
        threshold = _threshold;
    }

    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount)
        external
        payable
        onlyNormalMode
        whenNotPaused
    {
        _isWhiteListed();
        require(
            IAPContract(APContract).isDepositAsset(_tokenAddress),
            "Not approved deposit asset"
        );

        if (_tokenAddress == eth) {
            require(_amount == msg.value, "incorrect value");
        }

        managementFeeCleanUp();

        (bool result, ) = IAPContract(APContract)
            .getDepositStrategy()
            .delegatecall(
                abi.encodeWithSignature(
                    "deposit(address,uint256)",
                    _tokenAddress,
                    _amount
                )
            );
        revertDelegate(result);
        tokenBalances.setLastTransactionNAV(getVaultNAV());
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        external
        onlyNormalMode
    {
        _isWhiteListed();
        require(
            IAPContract(APContract).isWithdrawalAsset(_tokenAddress),
            "Not approved Withdrawal asset"
        );
        require(
            balanceOf(msg.sender) >= _shares,
            "You don't have enough shares"
        );

        managementFeeCleanUp();

        (bool result, ) = IAPContract(APContract)
            .getWithdrawStrategy()
            .delegatecall(
                abi.encodeWithSignature(
                    "withdraw(address,uint256)",
                    _tokenAddress,
                    _shares
                )
            );
        revertDelegate(result);
        tokenBalances.setLastTransactionNAV(getVaultNAV());
    }

    /// @dev Function to return balance amount in vault.
    /// @param _token Address of token whose balance amount has to be returned.
    function returnBalance(address _token) internal view returns (uint256) {
        uint256 amount;
        if (_token == eth) {
            amount = address(this).balance;
        } else if (_token != address(0)) {
            amount = IERC20(_token).balanceOf(address(this));
        }

        return amount;
    }

    /// @dev Function to deposit/withdraw vault assets to protocol
    /// @param _poolAddress Address of the protocol
    /// @param _instruction Encoded instruction to perform protocol deposit of vault tokens
    /// @param _amount Amount to be deposited to the protocol
    /// @param _fromToken Deposit token address
    /// @param _returnToken Address of the token returned by the protocol
    function protocolInteraction(
        address _poolAddress,
        bytes calldata _instruction,
        uint256[] calldata _amount,
        address[] calldata _fromToken,
        address[] calldata _returnToken
    ) external onlyNormalMode whenPaused {
        require(
            IAPContract(APContract).sdkContract() == msg.sender,
            "only thru sdk"
        );
        bool operationSatisfied;

        if (_instruction.length > 0) operationSatisfied = true;
        else if (_poolAddress == IAPContract(APContract).sdkContract())
            operationSatisfied = true;
        else operationSatisfied = false;

        require(operationSatisfied, "! supported opr");

        uint256[] memory returnTokenBalance = new uint256[](
            _returnToken.length
        );

        if (_returnToken.length > 0) {
            for (uint256 i = 0; i < _returnToken.length; i++) {
                returnTokenBalance[i] = returnBalance(_returnToken[i]);
                if (_returnToken[i] != address(0))
                    addToAssetList(_returnToken[i]);
            }
        }

        uint256 fromTokenEthAmount;

        if (_fromToken.length > 0) {
            require(_fromToken.length == _amount.length, "require same");
            for (uint256 i = 0; i < _fromToken.length; i++) {
                require(
                    _amount[i] <= tokenBalances.getTokenBalance(_fromToken[i]),
                    "insuff token present"
                );
                if (_fromToken[i] != eth)
                    _approveToken(_fromToken[i], _poolAddress, _amount[i]);
                else if (_fromToken[i] == eth)
                    fromTokenEthAmount = fromTokenEthAmount.add(_amount[i]);
            }
        }

        bool result;

        if (fromTokenEthAmount != 0) {
            (result, ) = _poolAddress.call{value: fromTokenEthAmount}(
                _instruction
            );
        } else if (_fromToken.length > 0) {
            if (_instruction.length > 0)
                (result, ) = _poolAddress.call(_instruction);
            else result = true;
        } else {
            (result, ) = _poolAddress.call(_instruction);
        }

        if (_fromToken.length > 0) {
            for (uint256 i; i < _fromToken.length; i++) {
                if (_fromToken[i] != address(0))
                    tokenBalances.setTokenBalance(
                        _fromToken[i],
                        tokenBalances.getTokenBalance(_fromToken[i]).sub(
                            _amount[i]
                        )
                    );
            }
        }

        if (_returnToken.length > 0)
            for (uint256 i = 0; i < _returnToken.length; i++) {
                if (_returnToken[i] != address(0)) {
                    uint256 returnTokenAmountAfter = returnBalance(
                        _returnToken[i]
                    );
                    tokenBalances.setTokenBalance(
                        _returnToken[i],
                        tokenBalances.getTokenBalance(_returnToken[i]).add(
                            returnTokenAmountAfter.sub(returnTokenBalance[i])
                        )
                    );
                }
            }

        revertDelegate(result);
    }

    /// @dev Function to get list of all the assets deposited to the vault
    function getAssetList() public view returns (address[] memory) {
        return assetList;
    }

    /// @dev Function to perform Management fee Calculations in the Vault.
    function managementFeeCleanUp() public {
        address[] memory managementFeeStrategies = IAPContract(APContract)
            .getVaultManagementFee();
        uint256 blockDifference;
        uint256 vaultCurrentNAV = getVaultNAV();
        if (tokenBalances.getLastTransactionBlockNumber() != 0) {
            blockDifference =
                uint256(block.number) -
                tokenBalances.getLastTransactionBlockNumber();
        } else {
            tokenBalances.setLastTransactionBlockNumber();
        }
        for (uint256 i = 0; i < managementFeeStrategies.length; i++) {
            (bool result, ) = managementFeeStrategies[i].delegatecall(
                abi.encodeWithSignature(
                    "executeSafeCleanUp(uint256,uint256)",
                    blockDifference,
                    vaultCurrentNAV
                )
            );
            if (result == false) {
                emit Response(
                    managementFeeStrategies[i],
                    "Failed in managementFeeCleanUp"
                );
            }
        }
        tokenBalances.setLastTransactionBlockNumber();
    }

    modifier onlyNormalMode() {
        _onlyNormalMode();
        _;
    }

    /// @dev Function to check if msg.sender is VaultAdmin.
    function _isVaultAdmin() private view {
        require(msg.sender == vaultAdmin, "not vaultAdmin");
    }

    /// @dev Function to check if msg.sender is yieldsterGOD.
    function _isYieldsterGOD() private view {
        require(
            msg.sender == IAPContract(APContract).yieldsterGOD(),
            "unauthorized"
        );
    }

    /// @dev Function that Disables vault interactions in case of Emergency Break and Emergency Exit.
    function _onlyNormalMode() private view {
        if (emergencyConditions == 1) {
            _isYieldsterGOD();
        } else if (emergencyConditions == 2) {
            revert("safe inactive");
        }
    }

    receive() external payable {
        etherDepositors.push(msg.sender);
        userEtherBalance[msg.sender] = userEtherBalance[msg.sender] + msg.value;
    }

    /// @dev Function to perform operation on Receival of ERC1155 token from Yieldster Strategy Minter.
    /// @param id Number denoting the type of instruction. 0 = safe Minter,2 = deposit strategy minter, 3 = withdrawal strategy minter.
    /// @param data Bytes containing encoded function call.
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes calldata data
    ) external virtual override onlyNormalMode returns (bytes4) {
        // managementFeeCleanUp();
        if (id == 0) {
            require(
                IAPContract(APContract).safeMinter() == msg.sender,
                "Only Minter"
            );
            (bool success, ) = IAPContract(APContract).safeUtils().delegatecall(
                data
            );
            revertDelegate(success);
        } else if (id == 2 || id == 3) {
            require(
                (IAPContract(APContract).getStrategyFromMinter(msg.sender) ==
                    IAPContract(APContract).getDepositStrategy()) ||
                    (IAPContract(APContract).getStrategyFromMinter(
                        msg.sender
                    ) == IAPContract(APContract).getWithdrawStrategy()),
                "Neither Dep/ Wdraw strat"
            );
            (bool success, ) = IAPContract(APContract)
                .getStrategyFromMinter(msg.sender)
                .delegatecall(data);
            revertDelegate(success);
        }

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /// @dev Function to pause a function.
    function toPause() external {
        require(
            msg.sender == vaultAdmin ||
                IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        _pause();
    }

    /// @dev Function to unpause a function.
    function unPause() external {
        require(
            msg.sender == vaultAdmin ||
                IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        _unpause();
    }

    /// @dev Function to getVaultSlippage.
    function getVaultSlippage() external view returns (uint256) {
        return IAPContract(APContract).getVaultSlippage();
    }

    /// @dev Function to change emergency vault
    /// @param _emergencyVault  address of the emergency vault
    function changeEmergencyVault(address _emergencyVault) public {
        _isVaultAdmin();
        emergencyVault = _emergencyVault;
    }

    /// @dev Function to clear assetList Array
    /// @param array  array of assetList indices to clear
    function removeFromAssetList(uint256[] calldata array) public {
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        for (uint256 i = 0; i < array.length; i++) {
            uint256 tempIndex = array[i];
            isAssetPresent[assetList[tempIndex]] = false;
            removeFromArray(tempIndex);
        }
    }

    function removeFromArray(uint256 index) internal {
        uint256 assetListLength = assetList.length - 1;
        assetList[index] = assetList[assetListLength];
        assetList.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    //function to setup name and symbol of the safe token once during safe creation
    function setupToken(string memory __name, string memory __symbol) internal {
        require(
            keccak256(abi.encodePacked((_name))) ==
                keccak256(abi.encodePacked((""))),
            "Token Name already assigned"
        );
        require(
            keccak256(abi.encodePacked((_symbol))) ==
                keccak256(abi.encodePacked((""))),
            "Token Symbol already assigned"
        );

        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(from, spender, currentAllowance - amount);
            }
        }

        _transfer(from, to, amount);

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
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received (
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) override
    external
    virtual
    returns(bytes4)
    {
   
    }

    function onERC1155BatchReceived (
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) override
    external
    returns(bytes4)
    {
 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../common/MasterCopy.sol";
import "../token/ERC20Detailed.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../token/ERC1155Receiver.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/IHexUtils.sol";
import "../interfaces/IWhitelist.sol";
import "./TokenBalanceStorage.sol";
import "../interfaces/IExchangeRegistry.sol";
import "../interfaces/IExchange.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/INAVUtils.sol";

contract VaultStorage is
    MasterCopy,
    ERC20Detailed,
    ERC1155Receiver,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant arrSize = 200;
    uint8 public emergencyConditions;
    bool internal vaultSetupCompleted;
    bool internal vaultRegistrationCompleted;
    address public APContract;
    address public owner;
    address public vaultAdmin;
    uint256[] internal whiteListGroups;
    mapping(uint256 => bool) isWhiteListGroupPresent;
    address[] public assetList;
    mapping(address => bool) internal isAssetPresent;
    address public strategyBeneficiary; // Performance Fee beneficiary
    uint256 public strategyPercentage; // Performance Fee percentage
    uint256 public threshold;
    address public eth;
    mapping(address => uint256) userEtherBalance;
    address[] public etherDepositors;
    address public emergencyVault;
    TokenBalanceStorage tokenBalances;

    bool public isTimeLocked;
    mapping(address => uint256) public vaultTokensUnlockedForUser;
    uint256 public lockedDuration;
    mapping(address => uint256) public latestDeposit;

    uint256 public platformFeeInterest;
    uint256 public managementFeeInterest;
    uint256 public performanceFeeInterest;

    address public managementBeneficiary; // Management Fee beneficiary
    uint256 public managementPercentage; // Management Fee percentage

    //TODO verify if this code has to be used for this fn
    /// @dev Function to revert in case of low level call fail.
    /// @param _delegateStatus Boolean indicating the status of low level call.
    function revertDelegate(bool _delegateStatus) internal pure {
        if (!_delegateStatus) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /// @dev Function to get the balance of token from tokenBalances.
    /// @param _tokenAddress Address of the token.
    function getTokenBalance(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        return tokenBalances.getTokenBalance(_tokenAddress);
    }

    /// @dev Function to add a token to assetList.
    /// @param _asset Address of the asset.
    function addToAssetList(address _asset) internal {
        require(_asset != address(0), "invalid asset address");
        if (!isAssetPresent[_asset]) {
            require(assetList.length + 1 <= arrSize, "Exceed length");
            assetList.push(_asset);
            isAssetPresent[_asset] = true;
        }
    }

    /// @dev Function to return the NAV of the Vault.
    function getVaultNAV() public view returns (uint256) {
        uint256 nav = 0;
        address wEth = IAPContract(APContract).getWETH();
        uint256 convexRes;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (tokenBalances.getTokenBalance(assetList[i]) > 0) {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                    assetList[i]
                );
                if (assetList[i] == eth) {
                    nav += IHexUtils(IAPContract(APContract).stringUtils())
                        .toDecimals(
                            wEth,
                            tokenBalances.getTokenBalance(assetList[i])
                        )
                        .mul(tokenUSD);
                } else {
                    nav += IHexUtils(IAPContract(APContract).stringUtils())
                        .toDecimals(
                            assetList[i],
                            tokenBalances.getTokenBalance(assetList[i])
                        )
                        .mul(tokenUSD);
                }
            }
            convexRes =
                convexRes +
                INAVUtils(IAPContract(APContract).getNavCalculator())
                    .getConvexNAV(assetList[i]);
        }
        nav = nav.div(1e18);
        uint256 accruedFees = platformFeeInterest +
            managementFeeInterest +
            performanceFeeInterest;
        // nav =
        //     nav -
        //     platformFeeInterest -
        //     managementFeeInterest -
        //     performanceFeeInterest +
        //     convexRes;
        // return nav;
        if ((nav + convexRes) > accruedFees) {
            nav = nav + convexRes - accruedFees;
            return nav;
        } else {
            nav = nav + convexRes;
            return nav;
        }
    }

    /// @dev Function to approve ERC20 token to the spendor.
    /// @param _token Address of the Token.
    /// @param _spender Address of the Spendor.
    /// @param _amount Amount of the tokens.
    function _approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _spender) > 0) {
            IERC20(_token).safeApprove(_spender, 0);
            IERC20(_token).safeApprove(_spender, _amount);
        } else IERC20(_token).safeApprove(_spender, _amount);
    }

    /// @dev Function to return NAV for Deposit token and amount.
    /// @param _tokenAddress Address of the deposit Token.
    /// @param _amount Amount of the Deposit tokens.
    function getDepositNAV(address _tokenAddress, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        address tokenAddress = _tokenAddress;
        if (tokenAddress == eth)
            tokenAddress = IAPContract(APContract).getWETH();
        return
            (
                IHexUtils(IAPContract(APContract).stringUtils())
                    .toDecimals(tokenAddress, _amount)
                    .mul(tokenUSD)
            ).div(1e18);
    }

    /// @dev Function to get the amount of Vault Tokens to be minted for the deposit NAV.
    /// @param depositNAV NAV of the Deposit Amount.
    function getMintValue(uint256 depositNAV) internal view returns (uint256) {
        return (depositNAV.mul(totalSupply())).div(getVaultNAV());
    }

    /// @dev Function to return Value of the Vault Token.
    function tokenValueInUSD() public view returns (uint256) {
        if (getVaultNAV() == 0 || totalSupply() == 0) {
            return 0;
        } else {
            return (getVaultNAV().mul(1e18)).div(totalSupply());
        }
    }

    /// @dev Function to update token balance in tokenBalances.
    /// @param tokenAddress Address of the Token.
    /// @param tokenAmount Amount of the tokens.
    /// @param isAddition Boolean indicating if token addition or substraction.
    function updateTokenBalance(
        address tokenAddress,
        uint256 tokenAmount,
        bool isAddition
    ) internal {
        if (isAddition) {
            tokenBalances.setTokenBalance(
                tokenAddress,
                tokenBalances.getTokenBalance(tokenAddress).add(tokenAmount)
            );
        } else {
            tokenBalances.setTokenBalance(
                tokenAddress,
                tokenBalances.getTokenBalance(tokenAddress).sub(tokenAmount)
            );
        }
    }

    /// @dev Function to return mapping details of ether depositors
    /// @param _address address to be queried
    function getEtherDepositor(address _address)
        external
        view
        returns (uint256)
    {
        return userEtherBalance[_address];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
        if (isTimeLocked == true) {
            if (from == address(0)) {
                latestDeposit[to] = block.number;
            }
            if (to == address(0)) {
                if (latestDeposit[from] + lockedDuration <= block.number) {
                    vaultTokensUnlockedForUser[from] = this.balanceOf(from);
                    latestDeposit[from] = 0;
                } else {
                    if (amount > vaultTokensUnlockedForUser[from])
                        revert("LKD");
                    vaultTokensUnlockedForUser[from] =
                        vaultTokensUnlockedForUser[from] -
                        amount;
                }
            }
        }
    }

    function setWithdrawLockPeriod(uint256 _lockDuration, bool _isTimeLocked)
        external
    {
        require(msg.sender == vaultAdmin, "!va");
        lockedDuration = _lockDuration;
        isTimeLocked = _isTimeLocked;
    }

    function unlockWithdraw() external {
        require(
            latestDeposit[msg.sender] + lockedDuration >= block.number,
            "TLK Active"
        );
        vaultTokensUnlockedForUser[msg.sender] = this.balanceOf(msg.sender);
    }

    function unlockWithdrawableAllowance(address _user, uint256 _unlocked)
        external
    {
        require(
            IAPContract(APContract).checkWalletAddress(msg.sender),
            "Unauthorized"
        );
        vaultTokensUnlockedForUser[_user] = _unlocked;
    }

    /// @dev Function to set Beneficiary Address and Percentage for performance fee.
    /// @param _beneficiary strategy beneficiary to which profit fee is given.
    /// @param _percentage percentage of profit fee to be given.
    function setBeneficiaryAndPercentage(
        address _beneficiary,
        uint256 _percentage
    ) external {
        require(msg.sender == vaultAdmin, "!va");
        strategyBeneficiary = _beneficiary;
        strategyPercentage = _percentage;
    }

    /// @dev Function to set Beneficiary Address and Percentage.
    /// @param _beneficiary strategy beneficiary to which profit fee is given.
    /// @param _percentage percentage of profit fee to be given.
    function setManagementFeeBeneficiaryAndPercentage(
        address _beneficiary,
        uint256 _percentage
    ) external {
        require(msg.sender == vaultAdmin, "!va");
        managementBeneficiary = _beneficiary;
        managementPercentage = _percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract TokenBalanceStorage {

    uint256 public blockNumber;
    uint256 public lastTransactionNAV;
    address private owner;
    mapping(address=>uint256) tokenBalance;

    constructor(){
        // blockNumber = block.number;
        owner = msg.sender;
    }

    /// @dev Function to set the balance of a token.
    /// @param _tokenAddress Address of the token.
    /// @param _balance Balance of the token.
    function setTokenBalance(address _tokenAddress, uint256 _balance) public {
        require(msg.sender == owner, "only Owner");
        tokenBalance[_tokenAddress] = _balance;
    }
    
    /// @dev Function to get the balance of a token.
    /// @param _token Address of the token.
   function getTokenBalance(address _token) public view returns (uint256) {
        return tokenBalance[_token];
    }

    /// @dev Function to set the block Number of the current transaction.
    function setLastTransactionBlockNumber() public{
        require(msg.sender==owner,"not authorized");
        blockNumber = block.number;
    }

    /// @dev Function to set the NAV of the vault in last transaction.
    /// @param _nav Nav of the vault.
    function setLastTransactionNAV(uint256 _nav) public{
        require(msg.sender==owner,"not authorized");
        lastTransactionNAV = _nav;
    }
    
    /// @dev Function to get the block Number of the last transaction.
    function getLastTransactionBlockNumber() public view returns (uint256) {
        return blockNumber;
    }

    /// @dev Function to get the NAV of the last transaction.
    function getLastTransactionNav() public view returns (uint256) {
        return lastTransactionNAV;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWhitelist {
    function isMember(uint256, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INAVUtils {
    function getConvexNAV(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IHexUtils {
    function fromHex(bytes calldata) external pure returns (bytes memory);

    function toDecimals(address, uint256) external view returns (uint256);

    function fromDecimals(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IExchangeRegistry {
    function getPair(address, address) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IExchange {
    function swap(
        address, //from
        address, //to
        uint256, //amount
        uint256 //minAmount
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAPContract {
    function getUSDPrice(address) external view returns (uint256);
    function stringUtils() external view returns (address);
    function yieldsterGOD() external view returns (address);
    function emergencyVault() external view returns (address);
    function whitelistModule() external view returns (address);
    function addVault(address,uint256[] calldata) external;
    function setVaultSlippage(uint256) external;
    function setVaultAssets(address[] calldata,address[] calldata,address[] calldata,address[] calldata) external;
    function changeVaultAdmin(address _vaultAdmin) external;
    function yieldsterDAO() external view returns (address);
    function exchangeRegistry() external view returns (address);
    function getVaultSlippage() external view returns (uint256);
    function _isVaultAsset(address) external view returns (bool);
    function yieldsterTreasury() external view returns (address);
    function setVaultStatus(address) external;
    function setVaultSmartStrategy(address, uint256) external;
    function getWithdrawStrategy() external returns (address);
    function getDepositStrategy() external returns (address);
    function isDepositAsset(address) external view returns (bool);
    function isWithdrawalAsset(address) external view returns (bool);
    function getVaultManagementFee() external returns (address[] memory);
    function safeMinter() external returns (address);
    function safeUtils() external returns (address);
    function getStrategyFromMinter(address) external view returns (address);
    function sdkContract() external returns (address);
    function getWETH()external view returns(address);
    function calculateSlippage(address ,address, uint256, uint256)external view returns(uint256);
    function vaultsCount(address) external view returns(uint256);
    function getPlatformFeeStorage() external view returns(address);
    function getManagementFeeStorage() external view returns(address);
    function getPerformanceFeeStorage() external view returns(address);
    function checkWalletAddress(address _walletAddress) external view returns(bool);
    function getNavCalculator() external view returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


/// @title MasterCopy - Base for master copy contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/YieldsterVaultProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract MasterCopy  {
    event ChangedMasterCopy(address masterCopy);

    modifier authorized() {
        require(
            msg.sender == address(this),
            "Method can only be called from this contract"
        );
        _;
    }
    // masterCopy always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private masterCopy;

    /// @dev Allows to upgrade the contract. This can only be done via a Safe transaction.
    /// @param _masterCopy New contract address.
    function changeMasterCopy(address _masterCopy) public authorized {
        // Master copy address cannot be null.
        require(
            _masterCopy != address(0),
            "Invalid master copy address provided"
        );
        masterCopy = _masterCopy;
        emit ChangedMasterCopy(_masterCopy);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}