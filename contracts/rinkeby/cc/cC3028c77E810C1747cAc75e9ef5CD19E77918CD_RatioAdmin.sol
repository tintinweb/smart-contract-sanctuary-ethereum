// SPDX-License-Identifier: GPL-3.0 License

pragma solidity >=0.8.0;

import "./interfaces/IRatioAdmin.sol";

import "./interfaces/IERC20.sol";


contract RatioAdmin is IRatioAdmin {

    address public immutable OWNER;

    mapping(address => uint) internal ratio;
    mapping(address => bool) internal isExists;
    address[] public tokens;

    constructor(address _owner) {
        OWNER = _owner;
    }

    modifier onlyOwner() {
        require(OWNER == msg.sender, "NOT_OWNER");
        _;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function getRatio(address token) public view override returns (uint) {
        uint8 tokenDecimals = IERC20(token).decimals();
        uint8 _decimals = decimals();

        if (_decimals >= tokenDecimals) {
            return ratio[token] * 10 ** (_decimals - tokenDecimals);

        } else {
            return ratio[token] / 10 ** (tokenDecimals - _decimals);
        }
    }

    function updateRatio(address token, uint _ratio) external override onlyOwner {
        if (!isExists[token]) {
            tokens.push(token);
            isExists[token] = true;
        }
        ratio[token] = _ratio;
        emit UpdateRatio(msg.sender, token, _ratio);
    }

    function destruct() external onlyOwner {
        selfdestruct(payable(OWNER));
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IRatioAdmin {

    event UpdateRatio(address indexed sender, address indexed token, uint ratio);

    function getRatio(address token) external view returns (uint ratio);
    function updateRatio(address token, uint ratio) external;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}