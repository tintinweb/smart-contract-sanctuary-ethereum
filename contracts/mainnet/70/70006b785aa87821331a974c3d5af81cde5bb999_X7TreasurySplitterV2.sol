/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract representing the treasury (v2)

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setOtherSlotRecipient(Outlet outlet, address recipient) external onlyOwner {
        require(outlet == Outlet.OTHER_SLOT1 || outlet == Outlet.OTHER_SLOT2);

        address oldRecipient = outletRecipient[outlet];
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function setOtherSlotShares(uint256 slot1Share, uint256 slot2Share) external onlyOwner {
        require(slot1Share + slot2Share == 51000);
        divvyUp();

        uint256 oldOtherSlot1Share = outletShare[Outlet.OTHER_SLOT1];
        uint256 oldOtherSlot2Share = outletShare[Outlet.OTHER_SLOT2];
        outletShare[Outlet.OTHER_SLOT1] = slot1Share;
        outletShare[Outlet.OTHER_SLOT2] = slot2Share;

        emit SharesSet(oldOtherSlot1Share, oldOtherSlot2Share, slot1Share, slot2Share);
    }


These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IX7TreasurySplitter {
    function takeBalance() external;
    function takeCurrentBalance() external;
    function divvyUp() external;
    function pushAll() external;
}

contract X7TreasurySplitterV2 is Ownable, IX7TreasurySplitter {

    enum Outlet {
        NONE,
        X7DEV1,
        X7DEV2,
        X7DEV3,
        X7DEV4,
        X7DEV5,
        X7DEV6,
        X7DEV7,
        REWARD_POOL,
        OTHER_SLOT1,
        OTHER_SLOT2
    }

    uint256 public reservedETH;
    IUniswapV2Router02 public router;

    mapping(Outlet => uint256) public outletBalance;
    mapping(Outlet => address) public outletRecipient;
    mapping(Outlet => uint256) public outletShare;
    mapping(address => Outlet) public outletLookup;
    mapping(Outlet => mapping(address => bool)) outletController;
    mapping(Outlet => bool) outletFrozen;

    event OutletControllerAuthorizationSet(Outlet indexed outlet, address indexed setter, address indexed controller, bool authorization);
    event OutletRecipientSet(Outlet indexed outlet, address indexed oldRecipient, address indexed newRecipient);
    event SharesSet(uint256 oldOtherSlot1Share, uint256 oldOtherSlot2Share, uint256 oldRewardPoolShare, uint256 newOtherSlot1Share, uint256 newOtherSlot2Share, uint256 newRewardPoolShare);
    event OutletRecipientFrozen(Outlet outlet);
    event RouterSet(address indexed router);

    constructor (address router_) Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        router = IUniswapV2Router02(router_);

        outletShare[Outlet.X7DEV1] = 7000;
        outletShare[Outlet.X7DEV2] = 7000;
        outletShare[Outlet.X7DEV3] = 7000;
        outletShare[Outlet.X7DEV4] = 7000;
        outletShare[Outlet.X7DEV5] = 7000;
        outletShare[Outlet.X7DEV6] = 7000;
        outletShare[Outlet.X7DEV7] = 7000;
        outletShare[Outlet.REWARD_POOL] = 6000;
        outletShare[Outlet.OTHER_SLOT1] = 15000;
        outletShare[Outlet.OTHER_SLOT2] = 30000;

        // Dev shares will be allocated on chain via transactions to validate control of
        // destinations addresses.
        outletController[Outlet.X7DEV1][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;
        outletController[Outlet.X7DEV2][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;
        outletController[Outlet.X7DEV3][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;
        outletController[Outlet.X7DEV4][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;
        outletController[Outlet.X7DEV5][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;
        outletController[Outlet.X7DEV6][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;
        outletController[Outlet.X7DEV7][address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)] = true;

        outletRecipient[Outlet.X7DEV1] = address(0x7000a09c425ABf5173FF458dF1370C25d1C58105);
        outletRecipient[Outlet.X7DEV2] = address(0x0000000000000000000000000000000000000000);
        outletRecipient[Outlet.X7DEV3] = address(0x0000000000000000000000000000000000000000);
        outletRecipient[Outlet.X7DEV4] = address(0x0000000000000000000000000000000000000000);
        outletRecipient[Outlet.X7DEV5] = address(0x0000000000000000000000000000000000000000);
        outletRecipient[Outlet.X7DEV6] = address(0x0000000000000000000000000000000000000000);
        outletRecipient[Outlet.X7DEV7] = address(0x0000000000000000000000000000000000000000);

        // Reward Pool
        outletRecipient[Outlet.REWARD_POOL] = address(0x0000000000000000000000000000000000000000);

        // Initial Community Gnosis Wallet
        outletRecipient[Outlet.OTHER_SLOT1] = address(0x7063E83dF5349833A21f744398fD39D42fbC00f8);

        // Initial Project Gnosis Wallet
        outletRecipient[Outlet.OTHER_SLOT2] = address(0x5CF4288Bf373BBe17f76948E39Baf33B9f6ac2e0);
    }

    receive () external payable {}

    function divvyUp() public {
        uint256 newETH = address(this).balance - reservedETH;

        if (newETH > 0) {
            outletBalance[Outlet.X7DEV1] += newETH * outletShare[Outlet.X7DEV1] / 100000;
            outletBalance[Outlet.X7DEV2] += newETH * outletShare[Outlet.X7DEV2] / 100000;
            outletBalance[Outlet.X7DEV3] += newETH * outletShare[Outlet.X7DEV3] / 100000;
            outletBalance[Outlet.X7DEV4] += newETH * outletShare[Outlet.X7DEV4] / 100000;
            outletBalance[Outlet.X7DEV5] += newETH * outletShare[Outlet.X7DEV5] / 100000;
            outletBalance[Outlet.X7DEV6] += newETH * outletShare[Outlet.X7DEV6] / 100000;
            outletBalance[Outlet.X7DEV7] += newETH * outletShare[Outlet.X7DEV7] / 100000;

            outletBalance[Outlet.REWARD_POOL] += newETH * outletShare[Outlet.REWARD_POOL] / 100000;
            outletBalance[Outlet.OTHER_SLOT1] += newETH * outletShare[Outlet.OTHER_SLOT1] / 100000;

            outletBalance[Outlet.OTHER_SLOT2] = address(this).balance -
            outletBalance[Outlet.X7DEV1] -
            outletBalance[Outlet.X7DEV2] -
            outletBalance[Outlet.X7DEV3] -
            outletBalance[Outlet.X7DEV4] -
            outletBalance[Outlet.X7DEV5] -
            outletBalance[Outlet.X7DEV6] -
            outletBalance[Outlet.X7DEV7] -
            outletBalance[Outlet.OTHER_SLOT1] -
            outletBalance[Outlet.REWARD_POOL];

            reservedETH = address(this).balance;
        }
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(router));
        router = IUniswapV2Router02(router_);
    }

    function setOutletControllerAuthorization(Outlet outlet, address controller, bool authorization) external {
        require(!outletFrozen[outlet]);
        require(outlet != Outlet.OTHER_SLOT1 && outlet != Outlet.OTHER_SLOT2);
        require(outletController[outlet][msg.sender]);
        outletController[outlet][controller] = authorization;

        emit OutletControllerAuthorizationSet(outlet, msg.sender, controller, authorization);
    }

    function setOutletRecipient(Outlet outlet, address recipient) external {
        require(!outletFrozen[outlet]);
        require(outletRecipient[outlet] != recipient);
        require(outletController[outlet][msg.sender]);
        require(outlet != Outlet.OTHER_SLOT1 && outlet != Outlet.OTHER_SLOT2 && outlet != Outlet.REWARD_POOL);
        outletLookup[recipient] = outlet;
        outletRecipient[outlet] = recipient;
    }

    function freezeOutlet(Outlet outlet) external {
        require(outlet != Outlet.OTHER_SLOT1 && outlet != Outlet.OTHER_SLOT2);
        require(outletController[outlet][msg.sender]);
        outletFrozen[outlet] = true;
    }

    function setOtherSlotRecipient(Outlet outlet, address recipient) external onlyOwner {
        require(outlet == Outlet.OTHER_SLOT1 || outlet == Outlet.OTHER_SLOT2 || outlet == Outlet.REWARD_POOL);
        require(!outletFrozen[outlet]);

        address oldRecipient = outletRecipient[outlet];
        outletLookup[recipient] = outlet;
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function setOtherSlotShares(uint256 slot1Share, uint256 slot2Share, uint256 rewardPoolShare) external onlyOwner {
        require(slot1Share + slot2Share + rewardPoolShare == 51000);
        divvyUp();

        uint256 oldOtherSlot1Share = outletShare[Outlet.OTHER_SLOT1];
        uint256 oldOtherSlot2Share = outletShare[Outlet.OTHER_SLOT2];
        uint256 oldRewardPoolShare = outletShare[Outlet.REWARD_POOL];
        outletShare[Outlet.OTHER_SLOT1] = slot1Share;
        outletShare[Outlet.OTHER_SLOT2] = slot2Share;
        outletShare[Outlet.REWARD_POOL] = rewardPoolShare;

        emit SharesSet(oldOtherSlot1Share, oldOtherSlot2Share, oldRewardPoolShare, slot1Share, slot2Share, rewardPoolShare);
    }

    function takeBalance() external {
        Outlet outlet = outletLookup[msg.sender];
        require(outlet != Outlet.NONE);
        divvyUp();
        _sendBalance(outlet);
    }

    function takeCurrentBalance() external {
        Outlet outlet = outletLookup[msg.sender];
        require(outlet != Outlet.NONE);
        _sendBalance(outlet);
    }

    function pushAll() public {
        divvyUp();
        _sendBalance(Outlet.X7DEV1);
        _sendBalance(Outlet.X7DEV2);
        _sendBalance(Outlet.X7DEV3);
        _sendBalance(Outlet.X7DEV4);
        _sendBalance(Outlet.X7DEV5);
        _sendBalance(Outlet.X7DEV6);
        _sendBalance(Outlet.X7DEV7);
        _sendBalance(Outlet.REWARD_POOL);
        _sendBalance(Outlet.OTHER_SLOT1);
        _sendBalance(Outlet.OTHER_SLOT2);
    }

    function rescueWETH() public {
        address weth = router.WETH();
        IWETH(weth).withdraw(IERC20(weth).balanceOf(address(this)));
        pushAll();
    }

    function rescueTokens(address tokenAddress) external {
        if (tokenAddress == router.WETH()) {
            rescueWETH();
        } else {
            uint256 tokenAmount = IERC20(tokenAddress).balanceOf(address(this));

            if (tokenAmount > 0) {
                address[] memory path = new address[](2);
                path[0] = tokenAddress;
                path[1] = router.WETH();

                IERC20(tokenAddress).approve(address(router), tokenAmount);
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                pushAll();
            }

        }
    }

    function _sendBalance(Outlet outlet) internal {
        bool success;
        address payable recipient = payable(outletRecipient[outlet]);

        if (recipient == address(0)) {
            return;
        }

        uint256 ethToSend = outletBalance[outlet];
        outletBalance[outlet] = 0;
        reservedETH -= ethToSend;

        (success,) = recipient.call{value: ethToSend}("");
        if (!success) {
            outletBalance[outlet] += ethToSend;
            reservedETH += ethToSend;
        }
    }
}