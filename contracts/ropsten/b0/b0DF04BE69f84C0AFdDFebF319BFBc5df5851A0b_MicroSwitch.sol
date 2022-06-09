//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
/*
    ██╗░██████╗████████╗██╗░░██╗░█████╗░████████╗███╗░░░███╗░█████╗░██╗░░██╗░░░███████╗████████╗██╗░░██╗
    ██║██╔════╝╚══██╔══╝██║░░██║██╔══██╗╚══██╔══╝████╗░████║██╔══██╗██║░██╔╝░░░██╔════╝╚══██╔══╝██║░░██║
    ██║╚█████╗░░░░██║░░░███████║███████║░░░██║░░░██╔████╔██║███████║█████═╝░░░░█████╗░░░░░██║░░░███████║
    ██║░╚═══██╗░░░██║░░░██╔══██║██╔══██║░░░██║░░░██║╚██╔╝██║██╔══██║██╔═██╗░░░░██╔══╝░░░░░██║░░░██╔══██║
    ██║██████╔╝░░░██║░░░██║░░██║██║░░██║░░░██║░░░██║░╚═╝░██║██║░░██║██║░╚██╗██╗███████╗░░░██║░░░██║░░██║
    ╚═╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝*/
/*
    ████████╗██╗░░██╗███████╗  ░██████╗░░█████╗░███╗░░░███╗███████╗
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝░██╔══██╗████╗░████║██╔════╝
    ░░░██║░░░███████║█████╗░░  ██║░░██╗░███████║██╔████╔██║█████╗░░
    ░░░██║░░░██╔══██║██╔══╝░░  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░
    ░░░██║░░░██║░░██║███████╗  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝*/
// designed for the curious. showcase intellegence with purity to win. enlightened players will prevail.
// art is a  horse. mak is unity. the core is mak. 625. wanna play?  [loading...]
// ₀₁₁₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₁₀₁ ₀₀₁₀₁₁₁₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₁ ₀₁₁₀₁₀₁₀ ₀₀₁₁₀₁₀₁ ₀₁₁₀₁₀₁₀ ₀₁₁₁₀₀₁₁ ₀₁₀₀₁₁₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₁₀₁₁₁ ₀₁₀₀₀₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₀₁₁₀₀₁ ₀₁₀₀₁₀₀₁
// ₀₁₀₁₀₁₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₀₁₁₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₀₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₀

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IMakController {
    function winner() external view returns (address);

    function _lastCall() external;
}

contract MicroSwitch {
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Router02 public immutable uniswapV2Router;

    //     IMakController public immutable makController;

    address MICRO = 0xBc28dF39Ccd6Be723f26230cD4dA5316a1387e08;
    address MAKMATIC = 0xe15052107408D51571b1b857F8EFEa9a10D3A711;
    address CORE;

    address BURN = 0x000000000000000000000000000000000000dEaD;
    uint256 tradeAllowenceMicro = 100000000000000000000; // consider functions to update this value
    uint256 tradeAllowenceMatic = 50000000000000000000; // consider functions to update this value

    address public mak;
    address public newOwner;
    uint256 coreCounter;
    bool public ripMak = false;
    uint256 totalTimesSwitched;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Router = _uniswapV2Router;
        mak = msg.sender;
    }

    // event logs
    event liquidityadded(
        address user,
        address token1,
        address address2,
        uint256 tokenAamount,
        uint256 tokenBamount
    );

    event Log(string message, uint256 val);

    event Received(address, uint256);

    //  modifiers
    modifier onlyMak() {
        require(msg.sender == mak);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == newOwner);
        _;
    }

    // contract payable
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setTheCore(address _theCore) public onlyMak {
        require(coreCounter == 0, "TheCore address has already been set");
        CORE = _theCore;
        coreCounter += 1;
    }

    function setTradeAllowence(uint256 _MicroAllowence, uint256 _MaticAllowence)
        public
        onlyMak
    {
        tradeAllowenceMicro = _MicroAllowence;
        tradeAllowenceMatic = _MaticAllowence;
    }

    /*
    ████████╗██╗░░██╗███████╗  ███████╗██╗░░░██╗███████╗██╗░░░░░
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝██║░░░██║██╔════╝██║░░░░░
    ░░░██║░░░███████║█████╗░░  █████╗░░██║░░░██║█████╗░░██║░░░░░
    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██║░░░██║██╔══╝░░██║░░░░░
    ░░░██║░░░██║░░██║███████╗  ██║░░░░░╚██████╔╝███████╗███████╗
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░░╚═════╝░╚══════╝╚══════╝*/
    // provides liquidity to the Micro token using the available Matic against the vol Micro needed to complete a successful liquidiuty trade.
    // 50% of all Micro token will be held on this contract and 50% distrubuted to The Core.
    // 10% of all primary and secondary sales in Maks Ecosystem will be used to create a Mi/MATIC liquidity pool ensuring a continuious rise in Micro token price.

    function theSwitch() external onlyMak {
        IERC20 token = IERC20(MICRO);
        IERC20 token2 = IERC20(MAKMATIC);
        token.approve(address(uniswapV2Router), tradeAllowenceMicro);
        token2.approve(address(uniswapV2Router), tradeAllowenceMatic);
        uniswapV2Router.addLiquidity(
            MICRO,
            MAKMATIC,
            tradeAllowenceMicro,
            tradeAllowenceMatic,
            1,
            1,
            msg.sender, // BURN for deploy. Remove after testing onn ropsten
            block.timestamp + 150
        );
        totalTimesSwitched += 1;
        _hasMakLeftTheBuilding();
        emit liquidityadded(
            msg.sender,
            MICRO,
            MAKMATIC,
            tradeAllowenceMicro,
            tradeAllowenceMatic
        );
    }

    /*
    ░██████╗░███████╗████████╗████████╗███████╗██████╗░░██████╗
    ██╔════╝░██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
    ██║░░██╗░█████╗░░░░░██║░░░░░░██║░░░█████╗░░██████╔╝╚█████╗░
    ██║░░╚██╗██╔══╝░░░░░██║░░░░░░██║░░░██╔══╝░░██╔══██╗░╚═══██╗
    ╚██████╔╝███████╗░░░██║░░░░░░██║░░░███████╗██║░░██║██████╔╝
    ░╚═════╝░╚══════╝░░░╚═╝░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░*/

    function switchedCount() public view returns (uint256) {
        return totalTimesSwitched;
    }

    function maticBalance() public view returns (uint256) {
        return IERC20(MAKMATIC).balanceOf(address(this));
    }

    function microBalance() public view returns (uint256) {
        return IERC20(MICRO).balanceOf(address(this));
    }

    function pairAddress(address _tokenA, address _tokenB)
        public
        view
        returns (IERC20)
    {
        return IERC20(uniswapV2Factory.getPair(_tokenA, _tokenB));
    }

    /*
    ██████╗░██╗██████╗░  ███╗░░░███╗░█████╗░██╗░░██╗
    ██╔══██╗██║██╔══██╗  ████╗░████║██╔══██╗██║░██╔╝
    ██████╔╝██║██████╔╝  ██╔████╔██║███████║█████═╝░
    ██╔══██╗██║██╔═══╝░  ██║╚██╔╝██║██╔══██║██╔═██╗░
    ██║░░██║██║██║░░░░░  ██║░╚═╝░██║██║░░██║██║░╚██╗
    ╚═╝░░╚═╝╚═╝╚═╝░░░░░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝*/

    function _hasMakLeftTheBuilding() internal {
        if (microBalance() < 1) {
            ripMak = true;
            IMakController(CORE)._lastCall();
            newOwner = IMakController(CORE).winner();
        }
    }

    /*
    ████████╗██╗░░██╗███████╗  ███████╗███╗░░██╗██████╗░
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝████╗░██║██╔══██╗
    ░░░██║░░░███████║█████╗░░  █████╗░░██╔██╗██║██║░░██║
    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██║╚████║██║░░██║
    ░░░██║░░░██║░░██║███████╗  ███████╗██║░╚███║██████╔╝
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚══════╝╚═╝░░╚══╝╚═════╝░*/
    // this contract will continue receiving primary and secondary sales of 10% eternally.
    // once makHasLeftTheBuilding(), emptyFunds() is available to newOwner.
    // the new owner is defined by your CORE contributions.

    function emptyFunds() public payable onlyOwner {
        require(ripMak == true, "Mak has not left the building yet.");
        require(msg.sender == newOwner, "Losers lose, winners win.");
        uint256 amount = maticBalance();
        IERC20 tokenContract = IERC20(MAKMATIC);
        tokenContract.transfer(msg.sender, amount);
    }

    // ₀₁₀₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₀₁₁₀₁ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₀
    // ₀₁₀₀₁₁₀₁ ₀₁₀₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₀₀₁₀₀₀ ₀₁₀₁₀₀₁₀ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₁₀₀₀₁₁₁ ₀₁₀₀₁₀₀₀ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₁₁ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₀₁₀ ₀₁₀₀₀₁₀₀ ₀₁₀₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₀₀₀ ₀₁₀₀₁₁₀₀ ₀₁₀₀₀₀₀₁ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₀₁ ₀₁₀₁₀₀₁₀ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₀₁₀₁₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₁₁₀₀ ₀₁₀₁₀₁₁₀ ₀₁₀₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₀₀₁ ₀₁₀₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₁₀ ₀₁₀₀₁₀₀₁ ₀₁₀₀₁₁₁₀ ₀₁₀₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₀₁₀₀₁ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₀₁ ₀₁₀₁₁₀₀₁ ₀₁₀₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₀₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₁₀₀₀₁ ₀₁₀₁₀₁₀₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₁₁₁₀ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₁₀₁
    // ₀₁₀₀₀₀₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₀₁₁₁₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₀₁₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₀₁₀ ₀₁₁₀₀₁₀₀ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₁₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₀₁ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₁₁ ₀₁₁₁₀₁₀₀ ₀₀₁₀₁₁₁₀

    // all  below the cut needs to be removed, address and cofirmed off chain before contract deployemnt to mainnet. ClEAN BELOW THE CUT
    function withdrawMicroToken() external onlyMak {
        uint256 amount = microBalance();
        IERC20 tokenContract = IERC20(MICRO);
        tokenContract.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}