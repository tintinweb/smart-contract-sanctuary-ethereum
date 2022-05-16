//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*
    ██╗░██████╗████████╗██╗░░██╗░█████╗░████████╗███╗░░░███╗░█████╗░██╗░░██╗░░░███████╗████████╗██╗░░██╗
    ██║██╔════╝╚══██╔══╝██║░░██║██╔══██╗╚══██╔══╝████╗░████║██╔══██╗██║░██╔╝░░░██╔════╝╚══██╔══╝██║░░██║
    ██║╚█████╗░░░░██║░░░███████║███████║░░░██║░░░██╔████╔██║███████║█████═╝░░░░█████╗░░░░░██║░░░███████║
    ██║░╚═══██╗░░░██║░░░██╔══██║██╔══██║░░░██║░░░██║╚██╔╝██║██╔══██║██╔═██╗░░░░██╔══╝░░░░░██║░░░██╔══██║
    ██║██████╔╝░░░██║░░░██║░░██║██║░░██║░░░██║░░░██║░╚═╝░██║██║░░██║██║░╚██╗██╗███████╗░░░██║░░░██║░░██║
    ╚═╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝
*/
/*
    ████████╗██╗░░██╗███████╗  ░██████╗░░█████╗░███╗░░░███╗███████╗
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝░██╔══██╗████╗░████║██╔════╝
    ░░░██║░░░███████║█████╗░░  ██║░░██╗░███████║██╔████╔██║█████╗░░
    ░░░██║░░░██╔══██║██╔══╝░░  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░
    ░░░██║░░░██║░░██║███████╗  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝
*/
/*
₀₁₁₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₁₀₁ ₀₀₁₀₁₁₁₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₁ ₀₁₁₀₁₀₁₀ ₀₀₁₁₀₁₀₁ ₀₁₁₀₁₀₁₀ ₀₁₁₁₀₀₁₁ ₀₁₀₀₁₁₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₁₀₁₁₁ ₀₁₀₀₀₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₀₁₁₀₀₁ ₀₁₀₀₁₀₀₁
*/
/*
₀₁₀₁₀₁₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₀₁₁₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₀₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₁₀₀ ₀₁₁₁₀₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₀₁₁ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₀
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MicroSwitch {
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Router02 public immutable uniswapV2Router;
    //address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //address WETH = 0xc778417e063141139fce010982780140aa0cd5ab; //returned from factory contract WETH() call.
    address MICRO = 0x0383e5a31C6b059D8D81f2548F65753F1C5C531D;
    address MAKMATIC = 0x0F8Ef2EE1182105A3421e8c4f63BdeA61a0BEeDa;

    uint256 availableMatic = IERC20(MAKMATIC).balanceOf(address(this));
    uint256 availableMicro = IERC20(MICRO).balanceOf(address(this));

    address public mak;
    address public newOwner;

    bool public ripMak = false;

    uint256 totalTimesSwitched = 0;

    constructor() {
        // uniswap router address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // sets Mak as the contract owner.
        mak = msg.sender;
    }

    event liquidityadded(
        address user,
        address token1,
        address address2,
        uint256 tokenAamount,
        uint256 tokenBamount
    );

    event liquidityremove(address user, address pairAddress, uint256 lptoken);

    event Log(string message, uint256 val);

    event Received(address, uint256);

    //  enables the contract to receive payment and emits the received event
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /*
    ████████╗██╗░░██╗███████╗  ███████╗██╗░░░██╗███████╗██╗░░░░░
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝██║░░░██║██╔════╝██║░░░░░
    ░░░██║░░░███████║█████╗░░  █████╗░░██║░░░██║█████╗░░██║░░░░░
    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██║░░░██║██╔══╝░░██║░░░░░
    ░░░██║░░░██║░░██║███████╗  ██║░░░░░╚██████╔╝███████╗███████╗
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░░╚═════╝░╚══════╝╚══════╝
*/
    // provides liquidity to the Micro token using the available Matic against the vol Micro needed to complete a successful liquidiuty trade.
    // 50% of the Micro token will be held on this contract and 50% disctrubuted to The Core.
    // 10% of all primary and secondary sales in Maks Ecosystem will be provided as MATIC to enable liquidity trades.

    function theSwitch() external {
        // do something here
        totalTimesSwitched += 1;
        makHasLeftTheBuilding();
        ripMak = false;
    }

    function addingLiquiditySwitch() external {
        IERC20 token = IERC20(MICRO);
        IERC20 token2 = IERC20(MAKMATIC);
        // tokens are approving router
        token.approve(address(uniswapV2Router), availableMicro);
        token2.approve(address(uniswapV2Router), availableMatic);
        uniswapV2Router.addLiquidity(
            MICRO,
            MAKMATIC,
            availableMicro,
            availableMatic,
            1,
            1,
            msg.sender,
            block.timestamp + 150
        );
        totalTimesSwitched += 1;
        emit liquidityadded(
            msg.sender,
            MICRO,
            MAKMATIC,
            availableMicro,
            availableMatic
        );
    }

    /*
    ░██████╗░███████╗████████╗████████╗███████╗██████╗░░██████╗
    ██╔════╝░██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
    ██║░░██╗░█████╗░░░░░██║░░░░░░██║░░░█████╗░░██████╔╝╚█████╗░
    ██║░░╚██╗██╔══╝░░░░░██║░░░░░░██║░░░██╔══╝░░██╔══██╗░╚═══██╗
    ╚██████╔╝███████╗░░░██║░░░░░░██║░░░███████╗██║░░██║██████╔╝
    ░╚═════╝░╚══════╝░░░╚═╝░░░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░
*/

    function ripMakStatus() public view returns (bool) {
        return ripMak;
    }

    function switchedCout() public view returns (uint256) {
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

    function CheckAllowance(IERC20 _Token) internal view returns (uint256) {
        return IERC20(_Token).allowance(msg.sender, address(this));
    }

    /*
    ██████╗░██╗██████╗░  ███╗░░░███╗░█████╗░██╗░░██╗
    ██╔══██╗██║██╔══██╗  ████╗░████║██╔══██╗██║░██╔╝
    ██████╔╝██║██████╔╝  ██╔████╔██║███████║█████═╝░
    ██╔══██╗██║██╔═══╝░  ██║╚██╔╝██║██╔══██║██╔═██╗░
    ██║░░██║██║██║░░░░░  ██║░╚═╝░██║██║░░██║██║░╚██╗
    ╚═╝░░╚═╝╚═╝╚═╝░░░░░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝
*/
    // when this contracts total supply of Micro is < 5 * 10**18,, ownership of the contract is updated to the highest Micro holder from The Core and the withdrawContractFunds function is available. Only the new owner of this contract can call the withdrawContractFunds function, enjoy.

    function makHasLeftTheBuilding() internal {
        // do something here
        if (ripMak = false && microBalance() < 5000000000000000000) {
            ripMak = true;
        } else {}
    }

    function assignNewOwner() internal {
        // newOwner get address of highest Micro holder from The Core
        if (availableMicro < 1) {
            newOwner = mak;
        }
    }

    /*
    ████████╗██╗░░██╗███████╗  ███████╗███╗░░██╗██████╗░
    ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝████╗░██║██╔══██╗
    ░░░██║░░░███████║█████╗░░  █████╗░░██╔██╗██║██║░░██║
    ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░██║╚████║██║░░██║
    ░░░██║░░░██║░░██║███████╗  ███████╗██║░╚███║██████╔╝
    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚══════╝╚═╝░░╚══╝╚═════╝░
*/

    function withdrawAllContractFunds() public {
        require(ripMak = true, "Mak has not left the building yet.");
        require(msg.sender == newOwner, "You are not the owner.");
        IERC20(MAKMATIC).transferFrom(address(this), newOwner, availableMatic);
        IERC20(MICRO).transferFrom(address(this), newOwner, availableMatic);
    }

    /*////////////////////////////////////////////////////////////////////////////////////////// below the line
    this contract will continue receiving primary and secondary sales % eternally.
    the new owner, assigned when availabeMICRO has been used up on providing liquidity.
    once the makHasLeftTheBuilding function is triggered, ownership is exchanged from Mak to the new owner and can never altered.
    */
    // ₀₁₀₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₀₁₁₀₁ ₀₁₁₀₀₁₀₁ ₀₀₁₀₁₁₁₀
    // ₀₁₀₀₁₁₀₁ ₀₁₀₁₁₀₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₀₀₁₀₀₀ ₀₁₀₁₀₀₁₀ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₁₀₀₀₁₁₁ ₀₁₀₀₁₀₀₀ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₁₁ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₀₁₀ ₀₁₀₀₀₁₀₀ ₀₁₀₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₀₀₀ ₀₁₀₀₁₁₀₀ ₀₁₀₀₀₀₀₁ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₀₁ ₀₁₀₁₀₀₁₀ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₁₀₀ ₀₁₀₁₀₁₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₁₁₀₀ ₀₁₀₁₀₁₁₀ ₀₁₀₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₀₀₁ ₀₁₀₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₁₀ ₀₁₀₀₁₀₀₁ ₀₁₀₀₁₁₁₀ ₀₁₀₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₀₀₁₁₁₁ ₀₁₀₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₀₁₀₀₁ ₀₁₀₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₀₀₀₁₀₁ ₀₁₀₁₁₀₀₁ ₀₁₀₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₀₁₀₀₁₁ ₀₁₀₀₀₁₀₁ ₀₁₀₁₀₀₀₁ ₀₁₀₁₀₁₀₁ ₀₁₀₀₀₁₀₁ ₀₁₀₀₁₁₁₀ ₀₁₀₀₀₀₁₁ ₀₁₀₀₀₁₀₁
    // ₀₁₀₀₀₀₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₀₁₁₁₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₀₁₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₀₁₀ ₀₁₁₀₀₁₀₀ ₀₀₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₀₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₁₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₁₁ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₀₀ ₀₁₁₀₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₀₁₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₁₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₀₀₁ ₀₁₁₁₀₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₀₁₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₀₁₁₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₁₁₀₀₁₀₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₁ ₀₁₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₁₀₀ ₀₁₁₀₁₀₀₀ ₀₁₁₀₀₁₀₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₁₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₀₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₁ ₀₁₁₀₀₁₀₀ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₀₀ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₀₁₁ ₀₁₁₀₁₀₁₁ ₀₀₁₀₀₀₀₀ ₀₁₁₀₁₁₁₁ ₀₁₁₀₁₁₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₁₀₀₁ ₀₁₁₀₁₁₁₁ ₀₁₁₁₀₁₀₁ ₀₁₁₁₀₀₁₀ ₀₀₁₀₀₀₀₀ ₀₁₁₁₀₀₀₁ ₀₁₁₁₀₁₀₁ ₀₁₁₀₀₁₀₁ ₀₁₁₁₀₀₁₁ ₀₁₁₁₀₁₀₀ ₀₀₁₀₁₁₁₀

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) external {
        IERC20 token = IERC20(_tokenA);
        IERC20 token2 = IERC20(_tokenB);
        token.transferFrom(msg.sender, address(this), _amountA);
        token2.transferFrom(msg.sender, address(this), _amountB);
        // tokens are approving router
        token.approve(address(uniswapV2Router), _amountA);
        token2.approve(address(uniswapV2Router), _amountB);
        uniswapV2Router.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            1,
            1,
            msg.sender,
            block.timestamp + 150
        );
        totalTimesSwitched += 1;
        emit liquidityadded(msg.sender, _tokenA, _tokenB, _amountA, _amountB);
    }

    // function addLiquidity(
    //     address _tokenA,
    //     address _tokenB,
    //     uint256 _amountA,
    //     uint256 _amountB
    // ) external {
    //     require(_amountA > 0, "Less TokenA Supply");
    //     require(_amountB > 0, "Less TokenB Supply");
    //     require(_tokenA != address(0), "DeAd address not allowed");
    //     require(_tokenB != address(0), "DeAd address not allowed");
    //     require(_tokenA != _tokenB, "Same Token not allowed");
    //     IERC20 token = IERC20(_tokenA);
    //     IERC20 token2 = IERC20(_tokenB);
    //     require(CheckAllowance(token) >= _amountA, "Lesser Supply");
    //     require(CheckAllowance(token2) >= _amountB, "Lesser Supply");
    //     token.transferFrom(msg.sender, address(this), _amountA);
    //     token2.transferFrom(msg.sender, address(this), _amountB);
    //     // tokens are approving router
    //     token.approve(address(uniswapV2Router), _amountA);
    //     token2.approve(address(uniswapV2Router), _amountB);
    //     uniswapV2Router.addLiquidity(
    //         _tokenA,
    //         _tokenB,
    //         _amountA,
    //         _amountB,
    //         1,
    //         1,
    //         msg.sender,
    //         block.timestamp + 150
    //     );
    //     totalTimesSwitched += 1;
    //     emit liquidityadded(msg.sender, _tokenA, _tokenB, _amountA, _amountB);
    // }

    function removingLiquidity(address _tokenA, address _tokenB) public {
        require(_tokenA != address(0), "DeAd address not allowed");
        require(_tokenB != address(0), "DeAd address not allowed");
        IERC20 pair = pairAddress(_tokenA, _tokenB);
        uint256 lptoken = IERC20(pair).balanceOf(msg.sender);
        pair.transferFrom(msg.sender, address(this), lptoken);
        pair.approve(address(uniswapV2Router), lptoken);
        uniswapV2Router.removeLiquidity(
            _tokenA,
            _tokenB,
            lptoken,
            1,
            1,
            msg.sender,
            block.timestamp + 150
        );
        emit liquidityremove(msg.sender, address(pair), lptoken);
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