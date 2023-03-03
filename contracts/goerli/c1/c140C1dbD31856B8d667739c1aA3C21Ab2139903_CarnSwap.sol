// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CarnSwap {
    address public immutable PLSD_TOKEN_ADDRESS;
    address public immutable PLSB_TOKEN_ADDRESS;
    address public immutable ASIC_TOKEN_ADDRESS;
    address public immutable HEX_TOKEN_ADDRESS;
    address public immutable CARN_TOKEN_ADDRESS;
    address public immutable CARNIVAL_BENEVOLENT_ADDRESS;

    uint256 public constant CARN_TO_PLSD_RATIO = 9; //assuming evaluation of $3 per plsd
    uint256 public constant CARN_TO_PLSB_RATIO = 3; //assuming evaluation of $1 per plsb
    uint256 public constant CARN_TO_ASIC_RATIO = 3; //assuming evaluation of $1 per asic
    uint256 public constant CARN_TO_HEX_RATIO = 3; //assuming evaluation of $0.10 per hex...see 1e1 below

    constructor(
        address plsdTokenAddress,
        address plsbTokenAddress,
        address asicTokenAddress,
        address hexTokenAddress,
        address carnTokenAddress,
        address carnival_benevolent_address
    ) {
        PLSD_TOKEN_ADDRESS = plsdTokenAddress;
        PLSB_TOKEN_ADDRESS = plsbTokenAddress;
        ASIC_TOKEN_ADDRESS = asicTokenAddress;
        HEX_TOKEN_ADDRESS = hexTokenAddress;
        CARN_TOKEN_ADDRESS = carnTokenAddress;
        CARNIVAL_BENEVOLENT_ADDRESS = carnival_benevolent_address;
    }

    function getCarnForPLSD(uint256 plsdAmount) public {
        require(plsdAmount > 0, "PLSD amount must be greater than zero");
        IERC20 plsdToken = IERC20(PLSD_TOKEN_ADDRESS);
        uint256 allowance = plsdToken.allowance(msg.sender, address(this));
        require(allowance >= plsdAmount, "PLSD allowance too low");

        uint256 carnAmount = plsdAmount * CARN_TO_PLSD_RATIO;
        IERC20 carnToken = IERC20(CARN_TOKEN_ADDRESS);
        uint256 carnBalance = carnToken.balanceOf(address(this));
        require(carnBalance >= carnAmount, "Not enough CARN in the contract");

        plsdToken.transferFrom(msg.sender, CARNIVAL_BENEVOLENT_ADDRESS, plsdAmount);
        carnToken.transfer(msg.sender, carnAmount);
    }

    function getCarnForPLSB(uint256 plsbAmount) public {
        require(plsbAmount > 0, "PLSB amount must be greater than zero");
        IERC20 plsbToken = IERC20(PLSB_TOKEN_ADDRESS);
        uint256 allowance = plsbToken.allowance(msg.sender, address(this));
        require(allowance >= plsbAmount, "PLSB allowance too low");

        uint256 carnAmount = plsbAmount * CARN_TO_PLSB_RATIO;
        IERC20 carnToken = IERC20(CARN_TOKEN_ADDRESS);
        uint256 carnBalance = carnToken.balanceOf(address(this));
        require(carnBalance >= carnAmount, "Not enough CARN in the contract");

        plsbToken.transferFrom(msg.sender, CARNIVAL_BENEVOLENT_ADDRESS, plsbAmount);
        carnToken.transfer(msg.sender, carnAmount);
    }

    function getCarnForASIC(uint256 asicAmount) public {
        require(asicAmount > 0, "ASIC amount must be greater than zero");
        IERC20 asicToken = IERC20(ASIC_TOKEN_ADDRESS);
        uint256 allowance = asicToken.allowance(msg.sender, address(this));
        require(allowance >= asicAmount, "ASIC allowance too low");

        uint256 carnAmount = asicAmount * CARN_TO_ASIC_RATIO;
        IERC20 carnToken = IERC20(CARN_TOKEN_ADDRESS);
        uint256 carnBalance = carnToken.balanceOf(address(this));
        require(carnBalance >= carnAmount, "Not enough CARN in the contract");

        asicToken.transferFrom(msg.sender, CARNIVAL_BENEVOLENT_ADDRESS, asicAmount);
        carnToken.transfer(msg.sender, carnAmount);
    }

    function getCarnForHEX(uint256 hexAmount) public {
        require(hexAmount > 0, "HEX amount must be greater than zero");
        IERC20 hexToken = IERC20(HEX_TOKEN_ADDRESS);
        uint256 allowance = hexToken.allowance(msg.sender, address(this));
        require(allowance >= hexAmount, "HEX allowance too low");

        uint256 carnAmount = hexAmount * 1e4 * CARN_TO_HEX_RATIO / 1e1;
        IERC20 carnToken = IERC20(CARN_TOKEN_ADDRESS);
        uint256 carnBalance = carnToken.balanceOf(address(this));
        require(carnBalance >= carnAmount, "Not enough CARN in the contract");

        hexToken.transferFrom(msg.sender, CARNIVAL_BENEVOLENT_ADDRESS, hexAmount);
        carnToken.transfer(msg.sender, carnAmount);
    }

}