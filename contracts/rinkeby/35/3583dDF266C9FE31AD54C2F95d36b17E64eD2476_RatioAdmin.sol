// SPDX-License-Identifier: GPL-3.0 License

pragma solidity >=0.8.0;

import "./interfaces/IRatioAdmin.sol";

import "./interfaces/ITreasury.sol";


contract RatioAdmin is IRatioAdmin {

    address public immutable OWNER;

    mapping(address => uint) internal ratio;
    mapping(address => bool) internal isExists;
    address[] public tokens;

    mapping(address => address) internal treasuries;

    bool public isOracleRatio;


    constructor(address _owner) {
        OWNER = _owner;
        isOracleRatio = true;
    }

    modifier onlyOwner() {
        require(OWNER == msg.sender, "NOT_OWNER");
        _;
    }

    function switchRatioSource() external {
        isOracleRatio = !isOracleRatio;
    }

    function putTreasury(address token, address treasury) external onlyOwner {
        require(token != address(0) && treasury != address(0), 'ZERO_ADDRESS');
        treasuries[token] = treasury;
    }

    function getTreasury(address token) public view returns (address) {
        return treasuries[token];
    }

    function getRatio(address token) public view override returns (uint) {
        if (isOracleRatio) {
            return ratio[token];

        } else {
            address treasury = getTreasury(token);
            require(treasury != address(0), 'TREASURY_NOT_FOUND');
            return ITreasury(treasury).get_ratio();
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


interface ITreasury {
    function get_total_amounts() external view returns (uint amount0, uint amount1, uint[] memory totalAmounts0, uint[] memory totalAmounts1, uint[] memory currentAmounts0, uint[] memory currentAmounts1);
    function get_tokens(uint reward, uint requestedAmount0, uint requestedAmount1, address to) external returns (uint sentToken, uint sentBlxm);
    function add_liquidity(uint amountBlxm, uint amountToken, address to) external;
    function get_ratio() external view returns (uint ratio);
}