pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "./ABDKMath64x64.sol";
import "./TransferHelper.sol";

contract StakingRateModel {
    using ABDKMath64x64 for *;

    uint public immutable initialTime;
    uint public immutable initialRate;

    /// @dev `_initialRate` is the expected initial rate divided by 16
    /// For example, if expected initial rate is 1, i.e., STAKING_RATE_BASE_UNIT
    /// then `_initialRate` passed in would be STAKING_RATE_BASE_UNIT / 16
    constructor(uint _initialRate) {
        initialTime = block.timestamp;
        initialRate = _initialRate;
    }

    /// @notice Base on `lockDuration` plus time since inital time, calculate the expected staking rate.
    /// Note that `lockDuration` must be greater than 30 minutes and less and 4 years (1 year = 365.25 days)
    /// Formula to calculate staking rate:
    /// `initialRate` * 2^((`lockDuration` + time_since_initial_time) / 1 year)
    /// @param lockDuration Duration to lock Dyson
    /// @return rate Staking rate
    function stakingRate(uint lockDuration) external view returns (uint rate) {
        if(lockDuration < 30 minutes) return 0;
        if(lockDuration > 1461 days) return 0;
        lockDuration = lockDuration + block.timestamp - initialTime;

        int128 lockPeriod = lockDuration.divu(365.25 days);
        int128 r = lockPeriod.exp_2();
        rate = r.mulu(initialRate);
    }
}

interface IsDYSONUpgradeReceiver {
    function onMigrationReceived(address, uint) external returns (bytes4);
}

contract sDYSON {
    using TransferHelper for address;

    struct Vault {
        uint dysonAmount;
        uint sDYSONAmount;
        uint unlockTime;
    }

    /// @dev For EIP-2612 permit
    bytes32 public immutable DOMAIN_SEPARATOR;
    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    /// @dev Max staking rate
    uint private constant STAKING_RATE_BASE_UNIT = 1e18;
    string public constant symbol = "sDYSN";
    string public constant name = "Sealed Dyson Sphere";
    uint8 public constant decimals = 18;
    address public immutable Dyson;
    /// @dev bytes4(keccak256("onMigrationReceived(address,uint256)"))
    bytes4 private constant _MIGRATE_RECEIVED = 0xc5b97e06;

    address public owner;
    /// @dev Migration contract for user to migrate to new staking contract
    address public migration;
    uint public totalSupply;

    StakingRateModel public currentModel;

    /// @notice User's sDyson amount
    mapping(address => uint) public balanceOf;
    /// @notice User's sDyson allowance for spender
    mapping(address => mapping(address => uint)) public allowance;
    /// @notice User's vault, indexed by number
    mapping(address => mapping(uint => Vault)) public vaults;
    /// @notice Number of vaults owned by user
    mapping(address => uint) public vaultCount;
    /// @notice Sum of dyson amount in all of user's current vaults
    mapping(address => uint) public dysonAmountStaked;
    /// @notice Sum of sDyson amount in all of user's current vaults
    mapping(address => uint) public votingPower;

    /// @notice User's permit nonce
    mapping(address => uint256) public nonces;

    event TransferOwnership(address newOwner);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Stake(address indexed vaultOwner, address indexed depositor, uint amount, uint sDYSONAmount, uint time);
    event Restake(address indexed vaultOwner, uint index, uint dysonAmountAdded, uint sDysonAmountAdded, uint time);
    event Unstake(address indexed vaultOwner, address indexed receiver, uint amount, uint sDYSONAmount);
    event Migrate(address indexed vaultOwner, uint index);

    constructor(address _owner, address dyson) {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        require(dyson != address(0), "DYSON_CANNOT_BE_ZERO");
        owner = _owner;
        Dyson = dyson;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        owner = _owner;

        emit TransferOwnership(_owner);
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /// @dev Mint sDyson
    function _mint(address to, uint amount) internal returns (bool) {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

    /// @dev Burn sDyson
    function _burn(address from, uint amount) internal returns (bool) {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] -= amount;
        }
        return _transfer(from, to, amount);
    }

    /// @notice Get staking rate
    /// @param lockDuration Duration to lock Dyson
    /// @return rate Staking rate
    function getStakingRate(uint lockDuration) public view returns (uint rate) {
        return currentModel.stakingRate(lockDuration);
    }

    /// @param newModel New StakingRateModel
    function setStakingRateModel(address newModel) external onlyOwner {
        currentModel = StakingRateModel(newModel);
    }

    /// @param _migration New Migration contract
    function setMigration(address _migration) external onlyOwner {
        migration = _migration;
    }

    /// @notice Stake on behalf of `to`
    /// @param to Address that owns the new vault
    /// @param amount Amount of Dyson to stake
    /// @param lockDuration Duration to lock Dyson
    /// @return sDYSONAmount Amount of sDyson minted to `to`'s new vault
    function stake(address to, uint amount, uint lockDuration) external returns (uint sDYSONAmount) {
        Vault storage vault = vaults[to][vaultCount[to]];
        sDYSONAmount = getStakingRate(lockDuration) * amount / STAKING_RATE_BASE_UNIT;
        require(sDYSONAmount > 0, "invalid lockup");

        vault.dysonAmount = amount;
        vault.sDYSONAmount = sDYSONAmount;
        vault.unlockTime = block.timestamp + lockDuration;
        
        dysonAmountStaked[to] += amount;
        votingPower[to] += sDYSONAmount;
        vaultCount[to]++;

        _mint(to, sDYSONAmount);
        Dyson.safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(to, msg.sender, amount, sDYSONAmount, lockDuration);
    }

    /// @notice Restake more Dyson to user's given vault. New unlock time must be greater than old unlock time.
    /// Note that user can restake even when the vault is unlocked
    /// @param index Index of user's vault to restake
    /// @param amount Amount of Dyson to restake
    /// @param lockDuration Duration to lock Dyson
    /// @return sDysonAmountAdded Amount of new sDyson minted to user's vault
    function restake(uint index, uint amount, uint lockDuration) external returns (uint sDysonAmountAdded) {
        require(index < vaultCount[msg.sender], "invalid index");
        Vault storage vault = vaults[msg.sender][index];
        require(vault.unlockTime < block.timestamp + lockDuration, "locked");
        uint sDysonAmountOld = vault.sDYSONAmount;
        uint sDysonAmountNew = (vault.dysonAmount + amount) * getStakingRate(lockDuration) / STAKING_RATE_BASE_UNIT;
        require(sDysonAmountNew > 0, "invalid lockup");

        sDysonAmountAdded = sDysonAmountNew - sDysonAmountOld;
        vault.dysonAmount += amount;
        vault.sDYSONAmount = sDysonAmountNew;
        vault.unlockTime = block.timestamp + lockDuration;

        dysonAmountStaked[msg.sender] += amount;
        votingPower[msg.sender] += sDysonAmountAdded;

        _mint(msg.sender, sDysonAmountAdded);
        if(amount > 0) Dyson.safeTransferFrom(msg.sender, address(this), amount);

        emit Restake(msg.sender, index, amount, sDysonAmountAdded, lockDuration);
    }

    /// @notice Unstake a given user's vault after the vault is unlocked and transfer Dyson to `to`
    /// @param to Address that will receive Dyson
    /// @param index Index of user's vault to unstake
    /// @param sDYSONAmount Amount of sDyson to unstake
    /// @return amount Amount of Dyson transferred
    function unstake(address to, uint index, uint sDYSONAmount) external returns (uint amount) {
        require(sDYSONAmount > 0, "invalid input amount");
        Vault storage vault = vaults[msg.sender][index];
        require(block.timestamp >= vault.unlockTime, "locked");
        require(sDYSONAmount <= vault.sDYSONAmount, "exceed locked amount");
        amount = sDYSONAmount * vault.dysonAmount / vault.sDYSONAmount;

        vault.dysonAmount -= amount;
        vault.sDYSONAmount -= sDYSONAmount;

        dysonAmountStaked[msg.sender] -= amount;
        votingPower[msg.sender] -= sDYSONAmount;

        _burn(msg.sender, sDYSONAmount);
        Dyson.safeTransfer(to, amount);
        
        emit Unstake(msg.sender, to, amount, sDYSONAmount);
    }

    /// @notice Migrate given user's vault to new staking contract
    /// @dev Owner must set `migration` before migrate.
    /// `migration` must implement `onMigrationReceived`
    /// @param index Index of user's vault to migrate
    function migrate(uint index) external {
        require(migration != address(0), "CANNOT MIGRATE");
        Vault storage vault = vaults[msg.sender][index];
        require(vault.unlockTime > 0, "INVALID VAULT");
        uint amount = vault.dysonAmount;
        require(IsDYSONUpgradeReceiver(migration).onMigrationReceived(msg.sender, index) == _MIGRATE_RECEIVED, "MIGRATION FAILED");
        Dyson.safeTransfer(migration, amount);
        _approve(msg.sender, migration, vault.sDYSONAmount);
        dysonAmountStaked[msg.sender] -= amount;
        votingPower[msg.sender] -= vault.sDYSONAmount;
        vault.dysonAmount = 0;
        vault.sDYSONAmount = 0;
        vault.unlockTime = 0;
        emit Migrate(msg.sender, index);
    }

    /// @notice rescue token stucked in this contract
    /// @param tokenAddress Address of token to be rescued
    /// @param to Address that will receive token
    /// @param amount Amount of token to be rescued
    function rescueERC20(address tokenAddress, address to, uint256 amount) onlyOwner external {
        require(tokenAddress != Dyson);
        tokenAddress.safeTransfer(to, amount);
    }

    /// @notice EIP-2612 permit
    function permit(
        address _owner,
        address _spender,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_owner != address(0), "zero address");
        require(block.timestamp <= _deadline || _deadline == 0, "permit is expired");
        bytes32 digest = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _amount, nonces[_owner]++, _deadline)))
        );
        require(_owner == ecrecover(digest, _v, _r, _s), "invalid signature");
        _approve(_owner, _spender, _amount);
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     * -2^127
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     * 2^127-1
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu (int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require (x >= 0);

            uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256 (int256 (x)) * (y >> 128);

            require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require (hi <=
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu (uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require (y != 0);
            uint128 result = divuu (x, y);
            require (result <= uint128 (MAX_64x64));
            return int128 (result);
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2 (int128 x) internal pure returns (int128) {
        unchecked {
            require (x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            if (x & 0x4000000000000000 > 0)
                result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            if (x & 0x2000000000000000 > 0)
                result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            if (x & 0x1000000000000000 > 0)
                result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            if (x & 0x800000000000000 > 0)
                result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            if (x & 0x400000000000000 > 0)
                result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            if (x & 0x200000000000000 > 0)
                result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            if (x & 0x100000000000000 > 0)
                result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            if (x & 0x80000000000000 > 0)
                result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            if (x & 0x40000000000000 > 0)
                result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            if (x & 0x20000000000000 > 0)
                result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            if (x & 0x10000000000000 > 0)
                result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            if (x & 0x8000000000000 > 0)
                result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            if (x & 0x4000000000000 > 0)
                result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            if (x & 0x2000000000000 > 0)
                result = result * 0x1000162E525EE054754457D5995292026 >> 128;
            if (x & 0x1000000000000 > 0)
                result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            if (x & 0x800000000000 > 0)
                result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            if (x & 0x400000000000 > 0)
                result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            if (x & 0x200000000000 > 0)
                result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            if (x & 0x100000000000 > 0)
                result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            if (x & 0x80000000000 > 0)
                result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            if (x & 0x40000000000 > 0)
                result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            if (x & 0x20000000000 > 0)
                result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            if (x & 0x10000000000 > 0)
                result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            if (x & 0x8000000000 > 0)
                result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            if (x & 0x4000000000 > 0)
                result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            if (x & 0x2000000000 > 0)
                result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            if (x & 0x1000000000 > 0)
                result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            if (x & 0x800000000 > 0)
                result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            if (x & 0x400000000 > 0)
                result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            if (x & 0x200000000 > 0)
                result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            if (x & 0x100000000 > 0)
                result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            if (x & 0x80000000 > 0)
                result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            if (x & 0x40000000 > 0)
                result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            if (x & 0x20000000 > 0)
                result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            if (x & 0x10000000 > 0)
                result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            if (x & 0x8000000 > 0)
                result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            if (x & 0x4000000 > 0)
                result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            if (x & 0x2000000 > 0)
                result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            if (x & 0x1000000 > 0)
                result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            if (x & 0x800000 > 0)
                result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            if (x & 0x400000 > 0)
                result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
            if (x & 0x200000 > 0)
                result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
            if (x & 0x100000 > 0)
                result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
            if (x & 0x80000 > 0)
                result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            if (x & 0x40000 > 0)
                result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            if (x & 0x20000 > 0)
                result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            if (x & 0x10000 > 0)
                result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            if (x & 0x8000 > 0)
                result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            if (x & 0x4000 > 0)
                result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            if (x & 0x2000 > 0)
                result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
            if (x & 0x1000 > 0)
                result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            if (x & 0x800 > 0)
                result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            if (x & 0x400 > 0)
                result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
            if (x & 0x200 > 0)
                result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            if (x & 0x100 > 0)
                result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
            if (x & 0x80 > 0)
                result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            if (x & 0x40 > 0)
                result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            if (x & 0x20 > 0)
                result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
            if (x & 0x10 > 0)
                result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            if (x & 0x8 > 0)
                result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            if (x & 0x4 > 0)
                result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            if (x & 0x2 > 0)
                result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
            if (x & 0x1 > 0)
                result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

            result >>= uint256 (int256 (63 - (x >> 64)));
            require (result <= uint256 (int256 (MAX_64x64)));

            return int128 (int256 (result));
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu (uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require (y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
                if (xc >= 0x10000) { xc >>= 16; msb += 16; }
                if (xc >= 0x100) { xc >>= 8; msb += 8; }
                if (xc >= 0x10) { xc >>= 4; msb += 4; }
                if (xc >= 0x4) { xc >>= 2; msb += 2; }
                if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

                result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
                require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert (xh == hi >> 128);

                result += xl / y;
            }

            require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128 (result);
        }
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}