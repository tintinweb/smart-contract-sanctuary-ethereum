/**
 *Submitted for verification at Etherscan.io on 2022-09-25
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

    function renounceOwnership() public virtual onlyOwner {
        address previousOwner = owner;
        owner = address(0);

        emit OwnershipTransferred(previousOwner, address(0));
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


abstract contract VaultBase is ERC20, SafeTransfer {

    address public immutable asset;

    event Deposit(address indexed caller, uint256 assets);
    event Withdraw(address indexed caller, uint256 assets);

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

    function deposit(uint256 assets) public virtual {
        require(assets != 0, "zero-assets");

        // Need to transfer before minting or ERC777s could reenter
        safeTransferFrom(asset, msg.sender, address(this), assets);

        _mint(msg.sender, assets);

        emit Deposit(msg.sender, assets);
    }

    function withdraw(uint256 assets) public virtual {
        _burn(msg.sender, assets);

        emit Withdraw(msg.sender, assets);

        safeTransfer(asset, msg.sender, assets);
    }
}


contract Vault is VaultBase, Ownable {

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public vTokenAddress;
    bool public vTokenEnabled;

    event SetAssetSpender(address indexed assetSpender, bool indexed value);
    event SetVTokenAddress(address indexed vTokenAddress);
    event SetVTokenEnabled(bool indexed isEnabled);
    event RedeemVToken(address indexed caller, uint256 amount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders
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
    }

    function setAssetSpender(address _assetSpender, bool _value) external onlyOwner {
        _setAssetSpender(_assetSpender, _value);
    }

    function setVToken(address _vTokenAddress, bool _isEnabled) external onlyOwner {
        // Zero address is allowed
        require(
            _vTokenAddress == address(0) || TokenDecimals(_vTokenAddress).decimals() == decimals,
            "token-decimals"
        );

        vTokenAddress = _vTokenAddress;

        emit SetVTokenAddress(_vTokenAddress);

        _setVTokenEnabled(_isEnabled);
    }

    function setVTokenEnabled(bool _isEnabled) external onlyOwner {
        _setVTokenEnabled(_isEnabled);
    }

    function redeemVToken(uint256 _amount) external {
        require(
            vTokenAddress != address(0),
            "token-not-set"
        );

        require(
            vTokenEnabled,
            "token-not-enabled"
        );

        TokenBurn(vTokenAddress).burnFrom(msg.sender, _amount);

        emit RedeemVToken(msg.sender, _amount);

        safeTransfer(asset, msg.sender, _amount);
    }

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
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

    function _setVTokenEnabled(bool _isEnabled) private {
        vTokenEnabled = _isEnabled;

        emit SetVTokenEnabled(_isEnabled);
    }
}