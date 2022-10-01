/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface TokenDecimals {
    function decimals() external pure returns (uint8);
}


interface TokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}


interface TokenBurn {
    function burnFrom(address _from, uint256 _amount) external;
}


abstract contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "only-owner"
        );

        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "owner-zero-address"
        );

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}


abstract contract ManagerRole is Ownable {

    mapping(address => bool) public managers;

    event SetManager(address indexed manager, bool indexed value);

    modifier onlyManager {
        require(
            managers[msg.sender],
            "only-manager"
        );

        _;
    }

    function setManager(address _manager, bool _value) public virtual onlyOwner {
        managers[_manager] = _value;

        emit SetManager(_manager, _value);
    }
}


abstract contract Pausable is ManagerRole {

    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(
            !paused,
            "when-not-paused"
        );

        _;
    }

    modifier whenPaused() {
        require(
            paused,
            "when-paused"
        );

        _;
    }

    function pause() onlyManager whenNotPaused public {
        paused = true;

        emit Pause();
    }

    function unpause() onlyManager whenPaused public {
        paused = false;

        emit Unpause();
    }
}


abstract contract ERC20 {

    string public name;
    string public symbol;
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        virtual
        returns (bool)
    {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance will never be larger than the total supply
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}


abstract contract SafeTransfer {

    function safeApprove(address _token, address _to, uint256 _value) internal {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-approve"
        );
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer"
        );
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer-from"
        );
    }

    function safeTransferNative(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        require(
            success,
            "safe-transfer-native"
        );
    }
}


abstract contract VaultBase is Pausable, ERC20, SafeTransfer {

    address public immutable asset;
    uint256 public totalSupplyLimit = type(uint256).max;

    event SetTotalSupplyLimit(uint256 limit);

    event Deposit(address indexed caller, uint256 assetAmount);
    event Withdraw(address indexed caller, uint256 assetAmount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    )
        ERC20(
            _name,
            _symbol,
            TokenDecimals(_asset).decimals()
        )
    {
        asset = _asset;
    }

    // Decimals = vault token decimals = asset decimals
    function setTotalSupplyLimit(uint256 _limit) external onlyManager {
        totalSupplyLimit = _limit;

        emit SetTotalSupplyLimit(_limit);
    }

    function deposit(uint256 assetAmount) public virtual whenNotPaused {
        require(
            assetAmount != 0,
            "asset-amount-zero"
        );

        require(
            totalSupply + assetAmount <= totalSupplyLimit,
            "total-supply-limit"
        );

        // Need to transfer before minting or ERC777s could reenter
        safeTransferFrom(asset, msg.sender, address(this), assetAmount);

        _mint(msg.sender, assetAmount);

        emit Deposit(msg.sender, assetAmount);
    }

    function withdraw(uint256 assetAmount) public virtual whenNotPaused {
        _burn(msg.sender, assetAmount);

        emit Withdraw(msg.sender, assetAmount);

        safeTransfer(asset, msg.sender, assetAmount);
    }
}


contract Vault is VaultBase {

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public variableToken;
    bool public variableTokenEnabled;

    event SetAssetSpender(address indexed assetSpender, bool indexed value);
    event SetVariableToken(address indexed variableToken);
    event SetVariableTokenEnabled(bool indexed isEnabled);
    event RedeemVariableToken(address indexed caller, uint256 amount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
        VaultBase(
            _asset,
            _name,
            _symbol
        )
    {
        for (uint256 index; index < _assetSpenders.length; index++) {
            _setAssetSpender(_assetSpenders[index], true);
        }

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    function setAssetSpender(address _assetSpender, bool _value) external onlyManager {
        _setAssetSpender(_assetSpender, _value);
    }

    function setVariableToken(address _variableToken, bool _isEnabled) external onlyManager {
        // Zero address is allowed
        require(
            _variableToken == address(0) || TokenDecimals(_variableToken).decimals() == decimals,
            "token-decimals"
        );

        variableToken = _variableToken;

        emit SetVariableToken(_variableToken);

        _setVariableTokenEnabled(_isEnabled);
    }

    function setVariableTokenEnabled(bool _isEnabled) external onlyManager {
        _setVariableTokenEnabled(_isEnabled);
    }

    function redeemVariableToken(uint256 _amount) external whenNotPaused {
        require(
            variableToken != address(0),
            "token-not-set"
        );

        require(
            variableTokenEnabled,
            "token-not-enabled"
        );

        TokenBurn(variableToken).burnFrom(msg.sender, _amount);

        emit RedeemVariableToken(msg.sender, _amount);

        safeTransfer(asset, msg.sender, _amount);
    }

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) external view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return TokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function _setAssetSpender(address _assetSpender, bool _value) private {
        safeApprove(asset, _assetSpender, 0);

        if (_value) {
            safeApprove(asset, _assetSpender, type(uint256).max);
        }

        emit SetAssetSpender(_assetSpender, _value);
    }

    function _setVariableTokenEnabled(bool _isEnabled) private {
        variableTokenEnabled = _isEnabled;

        emit SetVariableTokenEnabled(_isEnabled);
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}