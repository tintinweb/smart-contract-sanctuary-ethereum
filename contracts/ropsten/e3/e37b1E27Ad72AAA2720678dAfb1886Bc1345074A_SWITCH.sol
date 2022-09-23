//SPDX-License-Identifier: MIT
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

//import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
//import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ICore {
    function _lastCall() external;

    function winner() external view returns (address);
}

contract SWITCH {
    //   IUniswapV2Factory public immutable uniswapV2Factory;
    //   IUniswapV2Router02 public immutable uniswapV2Router;

    address MAKRO = 0xA085eAAB62C84002dA8A776bF162ea98abE294b5;
    address MATIK = 0xA2afD0Ae79FC722d7B2aBAB139be7808ddF0DCDC;
    address CORE;

    address BURN = 0x000000000000000000000000000000000000dEaD;
    uint256 tradeAllowenceMakro = 100000000000000000000;
    uint256 tradeAllowenceMatic = 50000000000000000000;

    address public mak;
    address public newOwner;
    uint256 coreCounter;
    bool public ripMak = false;
    uint256 totalTimesSwitched;

    constructor() {
        //         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //             0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        //         );
        //         uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        //         uniswapV2Router = _uniswapV2Router;
        mak = msg.sender;
    }

    event liquidityadded(
        address user,
        address token1,
        address address2,
        uint256 tokenAamount,
        uint256 tokenBamount
    );

    event Log(string message, uint256 val);

    event Received(address, uint256);

    modifier onlyMak() {
        require(msg.sender == mak);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == newOwner);
        _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setTheCore(address _theCore) public onlyMak {
        require(coreCounter == 0, "TheCore address has already been set");
        CORE = _theCore;
        coreCounter += 1;
    }

    function setTradeAllowence(uint256 _MakroAllowence, uint256 _MaticAllowence)
        public
        onlyMak
    {
        tradeAllowenceMakro = _MakroAllowence;
        tradeAllowenceMatic = _MaticAllowence;
    }

    /*
    ████████╗██╗░░██╗███████╗  ███████╗██╗░░░██╗███████╗██╗░░░░░
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝██║░░░██║██╔════╝██║░░░░░
    ░░░██║░░░███████║█████╗░░  █████╗░░██║░░░██║█████╗░░██║░░░░░
    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██║░░░██║██╔══╝░░██║░░░░░
    ░░░██║░░░██║░░██║███████╗  ██║░░░░░╚██████╔╝███████╗███████╗
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░░╚═════╝░╚══════╝╚══════╝*/
    // provides liquidity to the $MAK token using the available Matic against the vol $MAK needed to complete a successful liquidiuty trade.
    // 50% of all $MAK token will be held on this contract, 40% distrubuted to 0xCore and 10% transactionally distrubuted to the public.
    // 20% of all primary and secondary sales in Maks Ecosystem will be used to create a Mi/MATIC liquidity pool ensuring a continuious rise in $MAK token price.

    function theSwitch() public {
        // IERC20 token = IERC20(MAKRO);
        // IERC20 token2 = IERC20(MATIK);
        // token.approve(address(uniswapV2Router), tradeAllowenceMakro);
        // token2.approve(address(uniswapV2Router), tradeAllowenceMatic);
        // uniswapV2Router.addLiquidity(
        //     MAKRO,
        //     MATIK,
        //     tradeAllowenceMakro,
        //     tradeAllowenceMatic,
        //     1,
        //     1,
        //     msg.sender, // BURN for deploy. Remove after testing onn ropsten
        //     block.timestamp + 150
        // );
        totalTimesSwitched += 1;
        _hasMakLeftTheBuilding();
        // emit liquidityadded(
        //     msg.sender,
        //     MAKRO,
        //     MATIK,
        //     tradeAllowenceMakro,
        //     tradeAllowenceMatic
        // );
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
        return IERC20(MATIK).balanceOf(address(this));
    }

    function makroBalance() public view returns (uint256) {
        return IERC20(MAKRO).balanceOf(address(this));
    }

    // function pairAddress(address _tokenA, address _tokenB)
    //     public
    //     view
    //     returns (IERC20)
    // {
    //     return IERC20(uniswapV2Factory.getPair(_tokenA, _tokenB));
    // }

    /*
    ██████╗░██╗██████╗░  ███╗░░░███╗░█████╗░██╗░░██╗
    ██╔══██╗██║██╔══██╗  ████╗░████║██╔══██╗██║░██╔╝
    ██████╔╝██║██████╔╝  ██╔████╔██║███████║█████═╝░
    ██╔══██╗██║██╔═══╝░  ██║╚██╔╝██║██╔══██║██╔═██╗░
    ██║░░██║██║██║░░░░░  ██║░╚═╝░██║██║░░██║██║░╚██╗
    ╚═╝░░╚═╝╚═╝╚═╝░░░░░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝*/

    function _hasMakLeftTheBuilding() internal {
        if (makroBalance() < 1) {
            ripMak = true;
            ICore(CORE)._lastCall();
            newOwner = ICore(CORE).winner();
        }
    }

    /*
    ████████╗██╗░░██╗███████╗  ███████╗███╗░░██╗██████╗░
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝████╗░██║██╔══██╗
    ░░░██║░░░███████║█████╗░░  █████╗░░██╔██╗██║██║░░██║
    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██║╚████║██║░░██║
    ░░░██║░░░██║░░██║███████╗  ███████╗██║░╚███║██████╔╝
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚══════╝╚═╝░░╚══╝╚═════╝░*/
    // this contract will continue receiving primary and secondary sales of 20% eternally.
    // once makHasLeftTheBuilding(), emptyFunds() will be available to the newOwner.
    // the new owner is defined by 0xCORE contributions.

    function emptyFunds() public payable onlyOwner {
        require(ripMak == true, "Mak has not left the building yet.");
        require(msg.sender == newOwner, "Losers lose, winners win.");
        uint256 amount = maticBalance();
        IERC20 tokenContract = IERC20(MATIK);
        tokenContract.transfer(msg.sender, amount);
    }

    // ₀₁₀₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₀₁₁₀₁ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₀
    // ₀₁₀₀₁₁₀₁ ₀₁₀₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₀₀₁₀₀₀ ₀₁₀₁₀₀₁₀ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₁₀₀₀₁₁₁ ₀₁₀₀₁₀₀₀ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₁₁ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₀₁₀ ₀₁₀₀₀₁₀₀ ₀₁₀₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₀₀₀ ₀₁₀₀₁₁₀₀ ₀₁₀₀₀₀₀₁ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₀₁ ₀₁₀₁₀₀₁₀ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₀₁₀₁₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₁₁₀₀ ₀₁₀₁₀₁₁₀ ₀₁₀₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₀₀₁ ₀₁₀₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₁₀ ₀₁₀₀₁₀₀₁ ₀₁₀₀₁₁₁₀ ₀₁₀₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₀₁₀₀₁ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₀₁ ₀₁₀₁₁₀₀₁ ₀₁₀₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₀₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₁₀₀₀₁ ₀₁₀₁₀₁₀₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₁₁₁₀ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₁₀₁
    // ₀₁₀₀₀₀₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₀₁₁₁₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₀₁₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₀₁₀ ₀₁₁₀₀₁₀₀ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₁₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₀₁ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₁₁ ₀₁₁₁₀₁₀₀ ₀₀₁₀₁₁₁₀

    function withdrawmakroToken() external onlyMak {
        uint256 amount = makroBalance();
        IERC20 tokenContract = IERC20(MAKRO);
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