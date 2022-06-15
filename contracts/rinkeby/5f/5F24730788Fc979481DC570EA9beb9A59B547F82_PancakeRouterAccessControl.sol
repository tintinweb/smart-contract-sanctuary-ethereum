// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;


// for cobo safe module v0.4.0
contract PancakeRouterWithValueAccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WBNB
        _tokenWhitelist[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = true;
        // BUSD
        _tokenWhitelist[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
            
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(_checkedValue == 0, "invalid value");
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }
            
}


// for cobo safe module v0.3.0
contract PancakeRouterAccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WBNB
        _tokenWhitelist[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = true;
        // BUSD
        _tokenWhitelist[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods


    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }


    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
        require(path.length >= 2, "Invalid Path");
        require(_tokenWhitelist[path[0]], "Token is not allowed");
        require(_tokenWhitelist[path[path.length - 1]], "Token is not allowed");
        require(to == safeAddress, "To address is not allowed");
    }

}