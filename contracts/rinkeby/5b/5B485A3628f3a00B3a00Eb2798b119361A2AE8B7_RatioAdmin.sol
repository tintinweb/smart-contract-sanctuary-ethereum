// SPDX-License-Identifier: GPL-3.0 License

pragma solidity >=0.8.0;

import "./interfaces/IRatioAdmin.sol";


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

    function getRatio(address token) public view override returns (uint) {
        return ratio[token];
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