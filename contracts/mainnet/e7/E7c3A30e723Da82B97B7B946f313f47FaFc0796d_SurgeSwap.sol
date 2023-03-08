/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

//SPDX-License-Identifier: MIT

/**
 * Contract: SurgeSwap
 * Developed by: Heisenman
 * Team: t.me/ALBINO_RHINOOO, t.me/Heisenman, t.me/STFGNZ
 * Trade without dex fees. $SURGE is the inception of the next generation of decentralized protocols.
 *
 * Socials:
 * TG: https://t.me/SURGEPROTOCOL
 * Website: https://surgeprotocol.io/
 * Twitter: https://twitter.com/SURGEPROTOCOL
 */

pragma solidity 0.8.19;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IswapHelper{
    function SRG20forETH(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minETHOut,
        address SRG20Spent,
        address user
    ) external  returns (bool);

    function SRG20forSRG20(
        uint256 tokenAmount,
        uint256 deadline,
        address SRG20Spent
    ) external  returns (bool);
}

interface ISRG {
    function _buy(uint256 minTokenOut, uint256 deadline)
        payable
        external
        returns (bool);
    
    function _sell(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minBNBOut
    ) external  returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount)
        external
        returns (bool);
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);


}

interface ISRG20 {
    function _buy(
        uint256 buyAmount,
        uint256 minTokenOut,
        uint256 deadline
    ) external returns (bool);
    
    function _sell(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minBNBOut
    ) external returns (bool);

    
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount)
        external
        returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint8);
}


contract SurgeSwap is ReentrancyGuard{

    //SRG pair data
    address public SRG; 
    ISRG public SRGI;
    address public swapHelper = address(this);

    bool isSwapHelperSet = false;

    constructor(address _srgAddress)
    {
        SRG = _srgAddress;
        SRGI = ISRG(SRG);

    }

    function setSwapHelper(address _swapHelper) external {
        require(!isSwapHelperSet, "Helper is already set");
        swapHelper = _swapHelper;
        isSwapHelperSet = true;
    }

    function swapExactETHforSRG20(
        uint256 deadline,
        uint256 minSRG20Out,
        address SRG20
    ) external payable  returns (bool){
        
        // Buy the SRG with the ETH and figure out how much we got
        address buyer = msg.sender;
        uint256 balanceBefore = IERC20(SRG).balanceOf(address(this));
        bool temp1 = SRGI._buy{value: address(this).balance}( 0,deadline);
        require(temp1,"Failed to buy SRG!");
        uint256 balanceAfter = IERC20(SRG).balanceOf(address(this));
        uint256 change = balanceAfter - balanceBefore;

        //Approve the SRG20 to buy
        temp1 = IERC20(SRG).approve(SRG20, change);
        require(temp1,"Could not approve the SRG20");

        //Buy the SRG20 using SRG and figure out how much we got
        uint256 balanceBefore20 = IERC20(SRG20).balanceOf(address(this));
        temp1 = ISRG20(SRG20)._buy(change, minSRG20Out, deadline);
        require(temp1,"Failed to buy the SRG20!");
        uint256 balanceAfter20 = IERC20(SRG20).balanceOf(address(this));
        uint256 change20 = balanceAfter20-balanceBefore20;

         //transfer the received SRG20 to the msg sender
         temp1 = IERC20(SRG20).transfer(buyer, change20);
        require(temp1,"Failed to send the SRG20!");

        return true;
    }

    function swapExactSRG20forSRG20(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minSRG20Out,
        address SRG20Spent,
        address SRG20Received
    ) external nonReentrant returns (bool){
        address swapper = msg.sender;
        // transfer the SRG20Spent from the msg.sender to the swapHelper to sell them
        bool s1 = IERC20(SRG20Spent).transferFrom(swapper, swapHelper, tokenAmount);
        require(s1,"Failed to transfer SRG20Spent");

        // Sell the SRG20Spent and figure out how much SRG we got
        uint256 balanceBefore = IERC20(SRG).balanceOf(address(this));
        s1 = IswapHelper(swapHelper).SRG20forSRG20(tokenAmount, deadline, SRG20Spent);
        require(s1,"Failed to sell SRG20Spent");
        uint256 balanceAfter = IERC20(SRG).balanceOf(address(this));
        uint256 change = balanceAfter - balanceBefore;

        //Approve the SRG20 to buy
        s1  = IERC20(SRG).approve(SRG20Received, change);
        require(s1,"Could not approve the SRG20");

        // buy the SRG20Received and figure out how much we got
        uint256 balanceBefore20 = IERC20(SRG20Received).balanceOf(address(this));
        s1 = ISRG20(SRG20Received)._buy(change, minSRG20Out, deadline);
        require(s1, "Failed to buy SRG20Received!");
        uint256 balanceAfter20 = IERC20(SRG20Received).balanceOf(address(this));
        uint256 change20 = balanceAfter20 - balanceBefore20;

        //transfer the SRG20Received to the msg sender
        s1 = IERC20(SRG20Received).transfer(swapper, change20); 
        require(s1, "Failed to transfer the SRG20Received!");
        return true;
    }

    function swapExactSRG20forETH(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 minETHOut,
        address SRG20Spent
    ) external nonReentrant  returns (bool){
        address seller = msg.sender;
        // transfer the SRG20Spent from the msg.sender to the CA
        bool s1 = IERC20(SRG20Spent).transferFrom(msg.sender, swapHelper, tokenAmount);
        require(s1,"Failed to transfer SRG20Spent");

        s1 = IswapHelper(swapHelper).SRG20forETH(tokenAmount,deadline,minETHOut,SRG20Spent,seller);
        require(s1,"Failed to swap!");

        return true;
    }

    receive() external payable{}

}