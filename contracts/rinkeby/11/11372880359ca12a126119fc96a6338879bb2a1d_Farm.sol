/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ERC20Interface {

    function decimals() external pure returns (uint8);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function burn(uint256 _amount, address _burner) external returns (bool);
    function mint(uint256 _amount) external;
}

contract Farm {
    uint8 private _currentAPR = 20;

    /**
     * @dev Account Stakes
     */
    mapping(address => uint256) _stakeIndexByAddress;
    AccountStake[] stakes;
    struct AccountStake {
        uint256 staked;
        uint256 lastChangeTimestamp;
        uint256 yieldStored;
    }

    /**
     * @dev information about all Farm
     */
    uint256 private _totalStake = 0;
    uint256 private _totalYieldPaid = 0;

    // Inmutables
    uint256 private constant milisecondsPerYear = 60 * 60 * 24 * 365;
    address private _tokenAddress;
    address private _vaultAddress;
    ERC20Interface private _tokenContract;

    event Stake(address indexed _address, uint256 _value);
    event Unstake(address indexed _address, uint256 _value);
    event WithdrawYield(address indexed _address, uint256 _value);

    modifier MustHaveDeposit() {
        require(_stakeIndexByAddress[msg.sender] != 0, "Account doesn't have any deposit");
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0) && _address != address(this), 'The provided address is not valid');
        _;
    }

    /**
     * @dev Contract constructor with both TokenContract and Vault addresses
     */
    constructor(address _tokenContractAddress, address _vaultContractAddress) {
        _tokenAddress = _tokenContractAddress;
        _tokenContract = ERC20Interface(_tokenContractAddress);
        _vaultAddress = _vaultContractAddress;

        // Push an empty value to the array so we avoid using the index 0 in the array
        stakes.push();
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, 'Cannot stake nothing');
        // In token contract must exists a record that indicates that Farm.sol (contract) is allowed to spend certain value (_amount) on user's (msg.sender) behalf.
        require(_tokenContract.allowance(msg.sender, address(this)) >= _amount, 'Insufficient allowance');
        require(_tokenContract.balanceOf(msg.sender) >= _amount, 'Insufficient balance');

        // Move address's tokens to Farm's balance
        _tokenContract.transferFrom(msg.sender, address(this), _amount);
        _totalStake += _amount;

        // Update or create sender staking info
        if (_stakeIndexByAddress[msg.sender] == 0) {
            _stakeIndexByAddress[msg.sender] = stakes.length;

            stakes.push(AccountStake(_amount, block.timestamp, 0));
        } else {
            uint256 stakeIndex = _stakeIndexByAddress[msg.sender];
            AccountStake memory stakeData;
            stakeData = stakes[stakeIndex];

            // Update generated yields
            uint256 stakeYield = getYield(stakeData.staked, stakeData.lastChangeTimestamp);
            stakeData.yieldStored += stakeYield;

            // Update amount, and timestamp
            stakeData.staked += _amount;
            stakeData.lastChangeTimestamp = block.timestamp;
            stakes[stakeIndex] = stakeData;
        }

        emit Stake(address(msg.sender), _amount);
    }

    function unstake(uint256 _amount) external MustHaveDeposit {
        require(_amount > 0, 'Cannot unstake nothing');
        require(stakes[_stakeIndexByAddress[msg.sender]].staked >= _amount, 'Cannot unstake more than the staked amount');
        checkFarmLiquidity(_amount);

        // Get address staking info
        AccountStake memory stakeData = stakes[_stakeIndexByAddress[msg.sender]];

        // Calculate generated yield
        uint256 stakeYield = getYield(stakeData.staked, stakeData.lastChangeTimestamp);

        // Update account staking info
        stakeData.staked -= _amount;
        stakeData.yieldStored += stakeYield;
        stakeData.lastChangeTimestamp = block.timestamp;
        stakes[_stakeIndexByAddress[msg.sender]] = stakeData;
        _totalStake -= _amount;

        // Send tokens to address
        _tokenContract.transfer(msg.sender, _amount);
        emit Unstake(address(msg.sender), _amount);
    }

    function withdrawYield() external MustHaveDeposit {
        // Get address staking info
        AccountStake memory stakeData = stakes[_stakeIndexByAddress[msg.sender]];

        // Calculate generated yield
        uint256 stakeYield = getYield(stakeData.staked, stakeData.lastChangeTimestamp);
        uint256 yield = stakeYield + stakeData.yieldStored;

        // Check for Farm liquidity
        checkFarmLiquidity(yield);

        // Update account staking info
        stakeData.yieldStored = 0;
        stakeData.lastChangeTimestamp = block.timestamp;
        stakes[_stakeIndexByAddress[msg.sender]] = stakeData;
        _totalYieldPaid += yield;

        // Send yield to address
        _tokenContract.transfer(msg.sender, yield);
        emit WithdrawYield(msg.sender, yield);
    }

    function getYield() external view returns (uint256) {
        if (_stakeIndexByAddress[msg.sender] == 0) {
            return 0;
        }
        // Get address staking info
        AccountStake memory stakeData = stakes[_stakeIndexByAddress[msg.sender]];

        // Calculate generated yield
        uint256 stakeYield = getYield(stakeData.staked, stakeData.lastChangeTimestamp);
        uint256 yield = stakeYield + stakeData.yieldStored;

        return yield;
    }

    function getStake() external view returns (uint256) {
        AccountStake memory accountStake = stakes[_stakeIndexByAddress[msg.sender]];
        return accountStake.staked;
    }

    function getTotalStake() external view returns (uint256) {
        return _totalStake;
    }

    function getTotalYieldPaid() external view returns (uint256) {
        return _totalYieldPaid;
    }

    function getAPR() external view returns (uint256) {
        return _currentAPR;
    }

    function setAPR(uint8 _value) external {
        require(msg.sender == _vaultAddress, 'Only Vault can call this function');
        require(_value <= 100,'APR value is invalid');
        _currentAPR = _value;
    }

    function getYield(uint256 _staked, uint256 _lastChange) private view returns (uint256) {
        uint256 interest = (_currentAPR * (block.timestamp - _lastChange) * 10**5) / milisecondsPerYear;
        return (_staked * interest) / (100 * 10**5);
    }

    function checkFarmLiquidity(uint256 amount) private view {
        require(_tokenContract.balanceOf(address(this)) >= amount, 'Insufficient liquidity');
    }
}