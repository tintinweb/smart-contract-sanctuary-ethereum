// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract BaseV2TokenInterface {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address, address) external view returns (uint256) {}

    function approve(address _spender, uint256 _value)
        external
        returns (bool)
    {}

    function balanceOf(address) external view returns (uint256) {}

    function decimals() external view returns (uint8) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize() external {}

    function mint(address account, uint256 amount) external returns (bool) {}

    function minter() external view returns (address) {}

    function name() external view returns (string memory) {}

    function setMinter(address _minter) external {}

    function symbol() external view returns (string memory) {}

    function totalSupply() external view returns (uint256) {}

    function transfer(address _to, uint256 _value) external returns (bool) {}

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {}
}