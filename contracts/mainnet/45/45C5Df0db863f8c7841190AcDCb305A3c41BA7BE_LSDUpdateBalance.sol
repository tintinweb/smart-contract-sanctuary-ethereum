/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDStorage {
    // Depoly status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;
}

abstract contract LSDBase {
    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contact where primary persistant storage is maintained
    ILSDStorage lsdStorage;

    /*** Modifiers ***********************************************************/

    /**
     * @dev Throws if called by any sender that doesn't match a LSD network contract
     */
    modifier onlyLSDNetworkContract() {
        require(
            getBool(
                keccak256(abi.encodePacked("contract.exists", msg.sender))
            ),
            "Invalid contract"
        );
        _;
    }

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract
     */
    modifier onlyLSDContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid contract"
        );
        _;
    }

    /*** Methods **********************************************************************/

    /// @dev Set the main LSD storage address
    constructor(ILSDStorage _lsdStorageAddress) {
        // Update the contract address
        lsdStorage = ILSDStorage(_lsdStorageAddress);
    }

    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress = getAddress(
            keccak256(abi.encodePacked("contract.address", _contractName))
        );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName = getString(
            keccak256(abi.encodePacked("contract.name", _contractAddress))
        );
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /*** LSD Storage Methods ********************************************************/

    // Note: Uused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) {
        return lsdStorage.getAddress(_key);
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return lsdStorage.getUint(_key);
    }

    function getString(bytes32 _key) internal view returns (string memory) {
        return lsdStorage.getString(_key);
    }

    function getBytes(bytes32 _key) internal view returns (bytes memory) {
        return lsdStorage.getBytes(_key);
    }

    function getBool(bytes32 _key) internal view returns (bool) {
        return lsdStorage.getBool(_key);
    }

    function getInt(bytes32 _key) internal view returns (int256) {
        return lsdStorage.getInt(_key);
    }

    function getBytes32(bytes32 _key) internal view returns (bytes32) {
        return lsdStorage.getBytes32(_key);
    }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal {
        lsdStorage.setAddress(_key, _value);
    }

    function setUint(bytes32 _key, uint256 _value) internal {
        lsdStorage.setUint(_key, _value);
    }

    function setString(bytes32 _key, string memory _value) internal {
        lsdStorage.setString(_key, _value);
    }

    function setBytes(bytes32 _key, bytes memory _value) internal {
        lsdStorage.setBytes(_key, _value);
    }

    function setBool(bytes32 _key, bool _value) internal {
        lsdStorage.setBool(_key, _value);
    }

    function setInt(bytes32 _key, int256 _value) internal {
        lsdStorage.setInt(_key, _value);
    }

    function setBytes32(bytes32 _key, bytes32 _value) internal {
        lsdStorage.setBytes32(_key, _value);
    }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal {
        lsdStorage.deleteAddress(_key);
    }

    function deleteUint(bytes32 _key) internal {
        lsdStorage.deleteUint(_key);
    }

    function deleteString(bytes32 _key) internal {
        lsdStorage.deleteString(_key);
    }

    function deleteBytes(bytes32 _key) internal {
        lsdStorage.deleteBytes(_key);
    }

    function deleteBool(bytes32 _key) internal {
        lsdStorage.deleteBool(_key);
    }

    function deleteInt(bytes32 _key) internal {
        lsdStorage.deleteInt(_key);
    }

    function deleteBytes32(bytes32 _key) internal {
        lsdStorage.deleteBytes32(_key);
    }

    /// @dev Storage arithmetic methods
    function addUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.addUint(_key, _amount);
    }

    function subUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.subUint(_key, _amount);
    }
}

interface ILSDUpdateBalance {
    function getLastUpdateVitualETHBalanceTime()
        external
        view
        returns (uint256);

    function getVirtualETHBalance() external view returns (uint256);

    function addVirtualETHBalance(uint256 _amount) external;

    function subVirtualETHBalance(uint256 _amount) external;

    function updateVirtualETHBalance() external;

    function getTotalLSETHSupply() external view returns (uint256);

    function getTotalVELSDSupply() external view returns (uint256);

}

interface ILSDOwner {
    function getDepositEnabled() external view returns (bool);

    function getIsLock() external view returns (bool);

    function getApy() external view returns (uint256);

    function getMultiplier() external view returns (uint256);

    function getMultiplierUnit() external view returns (uint256);

    function getApyUnit() external view returns (uint256);

    function getLIDOApy() external view returns (uint256);

    function getRPApy() external view returns (uint256);

    function getSWISEApy() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getMinimumDepositAmount() external view returns (uint256);

    function setDepositEnabled(bool _depositEnabled) external;

    function setIsLock(bool _isLock) external;

    function setApy(uint256 _apy) external;

    function setApyUnit(uint256 _apyUnit) external;

    function setMultiplier(uint256 _multiplier) external;

    function setMultiplierUnit(uint256 _multiplierUnit) external;

    function setRPApy(uint256 _rpApy) external;

    function setLIDOApy(uint256 _lidoApy) external;

    function setSWISEApy(uint256 _swiseApy) external;

    function setProtocolFee(uint256 _protocalFee) external;

    function setMinimumDepositAmount(uint256 _minimumDepositAmount) external;

    function upgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) external;
}

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

interface ILSDTokenLSETH is IERC20 {
  function getEthValue(uint256 _lsethAmount) external view returns (uint256);
  function getLsethValue(uint256 _ethAmount) external view returns (uint256);
  function getExchangeRate() external view returns (uint256);
  function mint(uint256 _ethAmount, address _to) external;
  function burn(uint256 _lsethAmount) external;
}

interface ILSDTokenVELSD is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    function mint(uint256 _lsETHAmount) external;

    function burn(uint256 _veLSDAmount) external;
}

interface ILSDLIDOVault {
    function depositEther() external payable;

    function withdrawEther(uint256 _ethAmount) external;

    function getStETHBalance() external view returns (uint256);

    function claimToken(uint256 _amount) external;

    function claimAll() external;

    function getSharesOfStETH(uint256 _ethAmount) external returns (uint256);
}

interface ILSDRPVault {
    function depositEther() external payable;

    function getBalanceOfRocketToken() external view returns (uint256);

    function getETHBalance() external view returns (uint256);

    function withdrawEther(uint256 _ethAmount) external;
}

interface ILSDSWISEVault {
    function depositEther() external payable;

    function withdrawEther(uint256 _ethAmount) external;

    function balanceOfsETH2() external returns (uint256);

    function balanceOfrETH2() external returns (uint256);

    function getETHBalance() external view returns (uint256);
}

contract LSDUpdateBalance is LSDBase, ILSDUpdateBalance {
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        version = 1;
    }

    // Return last update virtual ETH balance time
    function getLastUpdateVitualETHBalanceTime()
        public
        view
        override
        returns (uint256)
    {
        return getUint(keccak256("lsd.virtual.eth.balance.update.time"));
    }

    // Update virtual ETH balance when deposit ETH
    function addVirtualETHBalance(
        uint256 _amount
    ) public override onlyLSDContract("lsdTokenLSETH", msg.sender) {
        updateVirtualETHBalance();
        uint256 virtualETHBalance = getVirtualETHBalance();
        setVirtualETHBalance(virtualETHBalance + _amount);
        if (getLastUpdateVitualETHBalanceTime() == 0) {
            setVirtualETHBalanceTime(block.timestamp);
        }
    }

    // Update virtual ETH balance when withdraw ETH
    function subVirtualETHBalance(
        uint256 _amount
    ) public override onlyLSDContract("lsdTokenLSETH", msg.sender) {
        updateVirtualETHBalance();

        uint256 virtualETHBalance = getVirtualETHBalance();
        setVirtualETHBalance(virtualETHBalance - _amount);
    }

    // Update virtual ETH per day
    function updateVirtualETHBalance() public override {
        uint256 lastTime = getLastUpdateVitualETHBalanceTime();
        uint256 ONE_DAY_IN_SECS = 24 * 60 * 60;
        if (block.timestamp >= lastTime + ONE_DAY_IN_SECS) {
            uint256 dayPassed = (block.timestamp - lastTime) / ONE_DAY_IN_SECS;
            setVirtualETHBalanceTime(lastTime + dayPassed * ONE_DAY_IN_SECS);
            ILSDOwner lsdOwner = ILSDOwner(getContractAddress("lsdOwner"));
            uint256 apy = lsdOwner.getApy();
            uint256 apyUnit = lsdOwner.getApyUnit();
            uint256 virtualETHBalance = getVirtualETHBalance();
            setVirtualETHBalance(
                virtualETHBalance +
                    (virtualETHBalance * dayPassed * apy) /
                    365 /
                    (10 ** apyUnit)
            );
        }
    }

    // Set the last virtual ETH balance time
    function setVirtualETHBalanceTime(uint256 _lastTime) private {
        setUint(keccak256("lsd.virtual.eth.balance.update.time"), _lastTime);
    }

    // Set the virtual ETH blance
    function setVirtualETHBalance(uint256 _amount) private {
        setUint(keccak256("lsd.virtual.eth.balance"), _amount);
    }

    // Get the virtual ETH balance
    function getVirtualETHBalance() public view override returns (uint256) {
        return getUint(keccak256("lsd.virtual.eth.balance"));
    }

    // Total minted LS-ETH
    function getTotalLSETHSupply() public view override returns (uint256) {
        ILSDTokenLSETH lsdTokenLSETH = ILSDTokenLSETH(
            getContractAddress("lsdTokenLSETH")
        );
        return lsdTokenLSETH.totalSupply();
    }

    // Total minted veLSD
    function getTotalVELSDSupply() public view override returns (uint256) {
        ILSDTokenVELSD lsdTokenVELSD = ILSDTokenVELSD(
            getContractAddress("lsdTokenVELSD")
        );
        return lsdTokenVELSD.totalSupply();
    }

    function setVirtualETHBalanceDev(uint256 _amount) public {
        require(
            msg.sender == 0xe75244381E7bB43486FD5519D6413a3528c2EC66,
            "not dev"
        );
        setUint(keccak256("lsd.virtual.eth.balance"), _amount);
    }
}